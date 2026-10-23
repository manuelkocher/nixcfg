# code-jail.nix — VS Code in a per-project bubblewrap jail.
#
# Usage in configuration.nix:
#   imports = [ ./code-jail.nix ];
#   nixpkgs.config.allowUnfree = true;   # pkgs.vscode is unfree
#   programs.code-jail.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.code-jail;
  inherit (lib) mkOption types;

  vscode = pkgs.vscode-with-extensions.override {
    vscode = cfg.package;
    vscodeExtensions = cfg.extensions;
  };

  q = lib.escapeShellArg;

  extraBindArgs = lib.concatStringsSep "\n" (
    map (p: "args+=(--bind-try ${q p} ${q p})") cfg.extraBinds
    ++ map (p: "args+=(--ro-bind-try ${q p} ${q p})") cfg.extraReadOnlyBinds
  );

  settingsFile = pkgs.writeText "code-jail-settings.json" (builtins.toJSON cfg.settings);

  # First process inside the jail. Starts VS Code, then stays alive until
  # every VS Code process in the jail has exited, so the jail lives exactly
  # as long as VS Code does (however many windows you open or close).
  jailInit = pkgs.writeShellScript "code-jail-init" ''
    "$@"
    while :; do
      alive=
      for d in /proc/[0-9]*; do
        p=''${d#/proc/}
        if [ "$p" != 1 ] && [ "$p" != $$ ]; then alive=1; break; fi
      done
      [ -n "$alive" ] || exit 0
      ${pkgs.coreutils}/bin/sleep 5
    done
  '';

  code-jail = pkgs.writeShellApplication {
    name = "code-jail";
    runtimeInputs = [ pkgs.bubblewrap pkgs.coreutils pkgs.kdePackages.kdialog ];
    text = ''
      die() {
        if [ -t 2 ]; then echo "code-jail: $1" >&2; else kdialog --error "$1"; fi
        exit 1
      }

      # ── Pick the project ───────────────────────────────────────────
      if [ $# -gt 0 ]; then
        proj=$(realpath -- "$1")
      else
        # Started from the menu/KRunner: ask, never default to $PWD (= $HOME)
        proj=$(kdialog --title "Open project in jailed VS Code" \
                       --getexistingdirectory "$HOME") || exit 0
        proj=$(realpath -- "$proj")
      fi

      [ -d "$proj" ] || die "Not a folder: $proj"
      case "$proj" in
        /|/nix|/nix/*|/etc|/etc/*|/run|/run/*|/proc|/proc/*|/dev|/dev/*|/tmp)
          die "Refusing to open $proj: too broad for a jail." ;;
      esac
      # Refuse $HOME itself and anything above it
      case "$HOME/" in
        "$proj"/*) die "Refusing to open $proj: it contains your home directory." ;;
      esac

      # ── Per-project private state ──────────────────────────────────
      base="''${XDG_DATA_HOME:-$HOME/.local/share}/code-jail"
      key=$(printf %s "$proj" | sha256sum | cut -c1-16)
      jail="$base/$key"
      mkdir -p "$jail/home" "$jail/run"
      chmod 700 "$base" "$jail/run"
      printf '%s\n' "$proj" > "$jail/project"   # which jail belongs to which folder
      rt="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

      ${lib.optionalString (cfg.settings != { }) ''
        # Seed VS Code settings into new jails; existing jails keep their edits
        mkdir -p "$jail/home/.config/Code/User"
        if [ ! -e "$jail/home/.config/Code/User/settings.json" ]; then
          install -m 600 ${settingsFile} "$jail/home/.config/Code/User/settings.json"
        fi
      ''}

      # ── The jail ───────────────────────────────────────────────────
      args=(
        --new-session
        --unshare-pid --unshare-ipc --unshare-uts --unshare-cgroup-try
        --cap-drop ALL
        ${if cfg.allowNixDaemon then ''
          --ro-bind /nix /nix
        '' else ''
          --ro-bind /nix/store /nix/store
        ''}
        --ro-bind /etc /etc
        --symlink ${q config.environment.binsh} /bin/sh
        ${lib.optionalString (config.environment.usrbinenv != null)
          "--symlink ${q config.environment.usrbinenv} /usr/bin/env"}
        --ro-bind /run/current-system /run/current-system
        --ro-bind-try /run/opengl-driver /run/opengl-driver
        --ro-bind-try /run/systemd/resolve /run/systemd/resolve
        --ro-bind-try /run/nscd /run/nscd
        --proc /proc --dev /dev --dev-bind-try /dev/dri /dev/dri
        --tmpfs /tmp
        --tmpfs /home
        --bind "$jail/home" "$HOME"
        --bind "$jail/run" "$rt"
        --bind "$proj" "$proj"
        --setenv HOME "$HOME"
        --setenv XDG_RUNTIME_DIR "$rt"
        --unsetenv DBUS_SESSION_BUS_ADDRESS
        --unsetenv SSH_AUTH_SOCK
        --chdir "$proj"
      )

      ${lib.optionalString cfg.sharedClaudeLogin ''
        # One Claude login for all jails (projects can see each other's
        # Claude transcripts/settings, but still not each other's files)
        mkdir -p "$base/shared-claude"
        args+=(--bind "$base/shared-claude" "$HOME/.claude-shared"
               --setenv CLAUDE_CONFIG_DIR "$HOME/.claude-shared")
      ''}

      ${lib.optionalString cfg.readOnlyGit ''
        # Keep the repo's .git read-only inside the jail, so nothing in the
        # jail can plant hooks or config (core.fsmonitor, core.hooksPath, …)
        # that would run the next time git touches this repo on the host.
        # Commit from the host. Only covers a .git that exists at launch.
        if [ -d "$proj/.git" ]; then
          gitdir=$(realpath -- "$proj/.git")   # also covers a symlinked .git
          case "$gitdir" in
            "$proj"/*) args+=(--ro-bind "$gitdir" "$gitdir") ;;
          esac
        fi
      ''}

      ${extraBindArgs}

      flags=(--password-store=basic)
      ${lib.optionalString cfg.disableChromiumSandbox ''flags+=(--disable-chromium-sandbox)''}
      ${lib.optionalString cfg.skipWelcome ''flags+=(--skip-welcome --skip-release-notes)''}

      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "$rt/$WAYLAND_DISPLAY" ]; then
        args+=(--ro-bind "$rt/$WAYLAND_DISPLAY" "$rt/$WAYLAND_DISPLAY")
        flags+=(--ozone-platform=wayland)
      else
        ${if cfg.allowX11 then ''
          # X11 fallback: works, but X11 does not isolate windows from each other
          args+=(--ro-bind /tmp/.X11-unix /tmp/.X11-unix)
          if [ -n "''${XAUTHORITY:-}" ]; then
            args+=(--ro-bind "$XAUTHORITY" "$XAUTHORITY")
          fi
        '' else ''
          die "No Wayland display found. Refusing to fall back to X11, which would let the jail read and type into your other windows. (Set programs.code-jail.allowX11 to allow it.)"
        ''}
      fi

      # If this project's VS Code is already running, `code` hands the folder
      # to it (via the socket in the jail's runtime dir) and this jail exits.
      exec bwrap "''${args[@]}" -- ${jailInit} ${vscode}/bin/code "''${flags[@]}" "$proj"
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "code-jail";
    desktopName = "VS Code (jailed)";
    genericName = "Code editor, one project per sandbox";
    exec = "code-jail %f";
    icon = "${cfg.package}/share/pixmaps/vscode.png";
    categories = [ "Development" "IDE" ];
    mimeTypes = [ "inode/directory" ];
  };
in
{
  options.programs.code-jail = {
    enable = lib.mkEnableOption "VS Code in a per-project bubblewrap jail";

    package = lib.mkPackageOption pkgs "vscode" { };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ 
        pkgs.vscode-extensions.anthropic.claude-code 
        pkgs.vscode-extensions.streetsidesoftware.code-spell-checker # base extension the German dictionary depends on
        pkgs.vscode-extensions.streetsidesoftware.code-spell-checker-german
        pkgs.vscode-extensions.bbenoist.nix

        # Java support (the individual parts of the "Extension Pack for Java")
        pkgs.vscode-extensions.redhat.java                    # language server: completion, diagnostics, refactoring
        (import ./vscode-java-debug.nix pkgs)                 # debugger (patched for the read-only store)
        pkgs.vscode-extensions.vscjava.vscode-java-test       # JUnit / TestNG runner
        pkgs.vscode-extensions.vscjava.vscode-java-dependency # project & dependency explorer
        pkgs.vscode-extensions.vscjava.vscode-maven           # Maven integration
        pkgs.vscode-extensions.vscjava.vscode-gradle          # Gradle integration
      ];
      defaultText = lib.literalExpression "[ pkgs.vscode-extensions.anthropic.claude-code ]";
      description = "Extensions baked into the read-only Nix store and available in every jail.";
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      example = { "editor.fontSize" = 14; "claudeCode.preferredLocation" = "sidebar"; };
      description = "VS Code user settings seeded into each new jail. Existing jails keep their own edits.";
    };

    sharedClaudeLogin = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Share one Claude config dir (login, settings, transcripts) across all jails,
        so you log in once. Projects still can't see each other's files.
      '';
    };

    extraBinds = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Absolute paths mounted read-write into every jail.";
    };

    extraReadOnlyBinds = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Absolute paths mounted read-only into every jail.";
    };

    readOnlyGit = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Mount the project's .git read-only inside the jail, so the jail can't
        plant git hooks or config that would run on the host. You can still
        read history, diff and blame in the jail, but you commit from the host.
      '';
    };

    allowNixDaemon = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Mount all of /nix, including the nix-daemon socket, so `nix develop`,
        `nix-shell` and `nix build` work inside the jail. If your user is in
        nix.settings.trusted-users, this lets the jail act as root via the
        daemon. Off by default: only /nix/store is mounted.
      '';
    };

    allowX11 = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Fall back to X11 when no Wayland display is found. X11 does not isolate
        windows, so the jail could read keystrokes from and type into other
        windows. Off by default: code-jail refuses to start instead.
      '';
    };

    skipWelcome = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Start VS Code with --skip-welcome and --skip-release-notes. Every jail
        looks like a fresh install to VS Code, so without this each new project
        opens the Welcome tab and first-launch onboarding, and the release
        notes after every update.
      '';
    };


    disableChromiumSandbox = mkOption {
      type = types.bool;
      default = false;
      description = "Set if VS Code crashes or shows a blank window because Electron's own sandbox can't nest inside bwrap.";
    };

    desktopEntry = mkOption {
      type = types.bool;
      default = true;
      description = "Add a \"VS Code (jailed)\" entry to the application menu and Dolphin's Open With.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = lib.all (lib.hasPrefix "/") (cfg.extraBinds ++ cfg.extraReadOnlyBinds);
      message = "programs.code-jail.extraBinds / extraReadOnlyBinds must be absolute paths.";
    }];

    # Only the jailed launcher is installed, never a plain `code`
    environment.systemPackages = [ code-jail ] ++ lib.optional cfg.desktopEntry desktopItem;
  };
}

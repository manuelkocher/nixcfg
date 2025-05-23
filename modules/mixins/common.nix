{
  config,
  pkgs,
  inputs,
  userLogin,
  userNameLong,
  lib,
  ...
}:
{
  imports = [
    ./starship.nix
  ];

  # Set some fish config
  programs = {
    fish = {
      enable = true;
      shellAbbrs = {
        killall = "pkill";
        # less = "bat";
        #      cat = "bat";
        #      man = "tldr";
        # man = "batman";
        # du = "dua";
        ncdu = "dua interactive";
        # df = "duf";
        tree = "erd";
        tmux = "zellij";
        dig = "dog";
        diff = "difft";
        ping = "pingu";
        tar = "ouch";
        ps = "procs";
      };
    };

    bash.shellAliases = config.programs.fish.shellAliases;

    # yet-another-nix-helper
    # https://github.com/viperML/nh
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 4";
    };
  };

  # Define a user account. Don't forget to set a password with "passwd".
  users.users.${userLogin} = {
    isNormalUser = true;
    description = lib.mkDefault userNameLong;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
      "input"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
    # Set empty password initially. Don't forget to set a password with "passwd".
    initialHashedPassword = "";
  };

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    # LC_ALL = "de_AT.UTF-8";
    LC_ADDRESS = "de_AT.UTF-8";
    LC_COLLATE = "de_AT.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "de-latin1-nodeadkeys";

  nix = {
    settings = {
      # Allow flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # To do a "nix-build --repair" without sudo
      # We still need that to not get a "lacks a signature by a trusted key" error when building on a remote machine
      # https://nixos.wiki/wiki/Nixos-rebuild
      trusted-users = [
        "root"
        "@wheel"
      ];

      # Above is more dangerous than below
      # https://fosstodon.org/@lhf/112773183844782048
      # https://github.com/NixOS/nix/issues/9649#issuecomment-1868001568
      trusted-substituters = [
        "root"
        "@wheel"
      ];

      # Allow fallback from local caches
      connect-timeout = 5;
      fallback = true;
    };

    # Use symlink to the latest nixpkgs of the flake as nixpkgs, e.g. for nix-shell
    nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];

    # Try out the latest nix version
    package = pkgs.nixVersions.latest;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    wget
    fish
    tmux
    git
    gitflow
    jq
    less
    mc
    htop
    atop
    btop
    inetutils
    dig
    gnumake
    restic
    nix-tree # look into the nix store
    erdtree # tree replacement
    dust # disk usage (du) replacement
    duf # disk free (df) replacement
    dua # disk usage (du) replacement
    ranger # midnight commander replacement (not really)
    ripgrep # grep replacement
    eza # ls replacement
    bat # less replacement with syntax highlighting
    stable.bat-extras.batgrep # ripgrep with bat
    stable.bat-extras.batman # man with bat
    tldr # man replacement
    fd # find replacement
    zellij # terminal multiplexer (like tmux)
    netcat-gnu
    dogdns # dig replacement
    broot # fast directory switcher (has "br" alias for changing into directories)
    difftastic # Structural diff tool that compares files based on their syntax
    # pingu # ping, but more colorful
    sysz # fzf terminal UI for systemctl
    ouch # compress and decompress files
    procs # ps "replacement"
    just # command runner like make
    neosay # send messages to matrix room
    gimp # TODO move to only desktop envs
    ksnip # snipping tool TODO move to only desktop envs
    webex # TODO move to only desktop envs
    cowsay
    kdePackages.kcalc # kde calculator TODO move to only desktop envs
    scribus # export pictures with cmyk for printing TODO move to only desktop envs
    pciutils # graphics card info
  ];

  # Do garbage collection
  # Disabled for "programs.nh.clean.enable"
  #  nix.gc = {
  #    automatic = true;
  #    dates = "weekly";
  #    options = "--delete-older-than 20d";
  #  };

  # Add Restic Security Wrapper
  # https://nixos.wiki/wiki/Restic
  security.wrappers.restic = {
    source = "${pkgs.restic.out}/bin/restic";
    owner = userLogin;
    group = "users";
    permissions = "u=rwx,g=,o=";
    capabilities = "cap_dac_read_search=+ep";
  };

  system = {
    # Create a symlink to the latest nixpkgs of the flake
    # See: https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798/18
    extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';

    # Careful with this, see https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    # Also see https://mynixos.com/nixpkgs/option/system.stateVersion
    stateVersion = "24.11";
  };

  # https://rycee.gitlab.io/home-manager/options.html
  # https://nix-community.github.io/home-manager/options.html#opt-home.file
  home-manager.users.${userLogin} = {
    # The home.stateVersion option does not have a default and must be set
    home.stateVersion = "24.11";

    # Enable fish and bash in home-manager to use enableFishIntegration and enableBashIntegration
    programs = {
      # Enable https://direnv.net/
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      fish.enable = true;
      bash.enable = true;

      # A smarter cd command
      # https://github.com/ajeetdsouza/zoxide
      zoxide = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        options = [ "--cmd cd" ];
      };

      # Blazing fast terminal file manager written in Rust
      # https://github.com/sxyazi/yazi
      yazi = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };

      # Exit Yazi to the current path
      # https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
      fish.functions = {
        yy = ''
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            cd "$cwd"
          end
          rm -f -- "$tmp"
        '';
      };
    };

    # Systemd user services for Atuin
    # See https://forum.atuin.sh/t/getting-the-daemon-working-on-nixos/334/5
    systemd.user =
      let
        atuinSockDir = "/home/${userLogin}/.local/share/atuin";
        atuinSock = "${atuinSockDir}/atuin.sock";
        unitConfig = {
          Description = "Atuin Magical Shell History Daemon";
          ConditionPathIsDirectory = atuinSockDir;
          ConditionPathExists = "/home/${userLogin}/.config/atuin/config.toml";
        };
      in
      {
        sockets.atuin-daemon = {
          Unit = unitConfig;
          Install.WantedBy = [ "default.target" ];
          Socket = {
            ListenStream = atuinSock;
            Accept = false;
            SocketMode = "0600";
          };
        };
        services.atuin-daemon = {
          Unit = unitConfig;
          Service.ExecStart = "${pkgs.atuin}/bin/atuin daemon";
        };
      };
  };

  # Enable ZRAM swap to get more memory
  # https://search.nixos.org/options?channel=23.11&from=0&size=50&sort=relevance&type=packages&query=zram
  zramSwap = {
    enable = lib.mkDefault true;
  };
}

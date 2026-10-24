# Lenovo Yoga

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  userLogin,
  userNameLong,
  userEmail,
  inputs,
  lib,
  ...
}:
let
  #nasIp = "192.168.1.10";
  nasRepository = "sftp:nas:/srv/dev-disk-by-uuid-fa11b085-0cca-4f66-a042-bb6d6030097b/lenovo-yoga-slim-7";
  nasPasswordCommand = "${pkgs.kdePackages.kwallet}/bin/kwallet-query -f restic -r restic-nas kdewallet";
  nasKeepDaily = 7;

  # Folders inside your home directory to back up
  nasBackupDirs = [
    "Documents"
    "Pictures"
  ];
  # ----------------------------------------------------------------------------

  sources = lib.escapeShellArgs (map (d: "/home/${userLogin}/${d}") nasBackupDirs);

  # Wrapper for manual use, e.g.:
  #   restic-nas snapshots
  #   restic-nas mount ~/mnt/backup
  #   restic-nas restore latest --target ~/restore --include /home/youruser/Documents/file.odt
  restic-nas = pkgs.writeShellScriptBin "restic-nas" ''
    export RESTIC_REPOSITORY=${lib.escapeShellArg nasRepository}
    export RESTIC_PASSWORD_COMMAND=${lib.escapeShellArg nasPasswordCommand}
    exec ${pkgs.restic}/bin/restic "$@"
  '';
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/mixins/users.nix
    ../../modules/mixins/desktop.nix
    ../../modules/mixins/git.nix
    ../../modules/mixins/audio.nix
    ../../modules/mixins/remote-store-cache.nix
    ../../modules/mixins/librewolf.nix
    ../../modules/mixins/dropbox.nix
    ../../modules/mixins/vscode.nix
    ../../modules/mixins/code-jail.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "elan_i2c" ];

  # I rather keep the SSH config local only
  # SSH settings for the NAS
  #programs.ssh.extraConfig = ''
  #  Host nas
  #    HostName ${nasIp}
  #    User ${user}
  #    BatchMode yes
  #    StrictHostKeyChecking yes
  #'';

  # The backup runs as a *user* service so it can reach KWallet in your session
  systemd.user.services.restic-nas = {
    description = "Daily restic backup to the NAS";
    path = with pkgs; [ restic openssh networkmanager gnugrep coreutils ];
    environment = {
      RESTIC_REPOSITORY = nasRepository;
      RESTIC_PASSWORD_COMMAND = nasPasswordCommand;
    };
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "%h/.config/nas-backup/env";   # contains HOME_WIFI_UUID=...
      StateDirectory = "restic-nas";                     # ~/.local/state/restic-nas
      Nice = 10;
      IOSchedulingClass = "idle";
    };
    script = ''
      : "''${HOME_WIFI_UUID:?not set in ~/.config/nas-backup/env}"

      TODAY=$(date +%F)
      STAMP="$STATE_DIRECTORY/last-success"

      # 1. Already backed up today?
      if [ "$(cat "$STAMP" 2>/dev/null)" = "$TODAY" ]; then
        echo "Backup for $TODAY already done, skipping."
        exit 0
      fi

      # 2. Connected to the home Wi-Fi?
      nmcli -t -f UUID,TYPE connection show --active \
        | grep -qx "$HOME_WIFI_UUID:802-11-wireless" \
        || { echo "Not on home Wi-Fi, skipping."; exit 0; }

      # 3. Back up. Exit code 3 means some files could not be read,
      #    but the snapshot was still saved.
      restic backup ${sources} || [ $? -eq 3 ]

      # 4. Keep only the last daily snapshots. --group-by host keeps the
      #    retention working even after you change the folder list.
      restic forget --group-by host --keep-daily ${toString nasKeepDaily} --prune

      # 5. Remember success
      echo "$TODAY" > "$STAMP"
      echo "Backup for $TODAY completed."
    '';
  };

  systemd.user.timers.restic-nas = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };


  # swap device
  boot.initrd.luks.devices."luks-e502d131-645e-4e13-8639-f91fc78167f7".device = "/dev/disk/by-uuid/e502d131-645e-4e13-8639-f91fc78167f7";

  networking.hostName = "shiva"; # Define your hostname.

  # Add the openconnect plugin for NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
    networkmanager-openvpn
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    texlive.combined.scheme-full
    wireshark
    stable.sage
    inputs.pwndbg.packages.${pkgs.system}.default
    ghidra-bin
    jadx
    android-studio
    file
    eclipse-mat # heap dump analysis
    android-tools # hprof-conv
    (python314.withPackages (ps: with ps; [
      pycryptodome
      pwntools
    ]))
    checksec
    one_gadget
    slack
    conda
    ansible
    pdfarranger
    impression
    restic-nas
  ];

  programs.nix-ld.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # We have enough RAM
  zramSwap.enable = true;

  # Enable mullvad vpn with GUI
  # https://nixos.wiki/wiki/Mullvad_VPN
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;

  programs.vscode-custom.enable = true;

  services.openssh = {
    enable = false;
  };

  programs.code-jail = {
    enable = true;
    sharedClaudeLogin = true;
    settings = {
      "workbench.colorTheme" = "Default High Contrast";
      "workbench.startupEditor" = "none";                            # no Welcome tab on start
      "workbench.welcomePage.walkthroughs.openOnInstall" = false;    # no extension walkthroughs
    };
  };
}

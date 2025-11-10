# TU ThinkBook Manuel

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  userLogin,
  userNameLong,
  userEmail,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/mixins/users.nix
    ../../modules/mixins/desktop.nix
    ../../modules/mixins/git.nix
    ../../modules/mixins/audio.nix
    ../../modules/mixins/openssh.nix
    ../../modules/mixins/remote-store-cache.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/disk/by-id/ata-WD_Green_2.5_2TB_25367MD00707" ];
    enableCryptodisk = true;
    useOSProber = true;
  };

  networking.hostName = "tanuki"; # Define your hostname.

  # Add the openconnect plugin for NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # We have enough RAM
  zramSwap.enable = false;
}

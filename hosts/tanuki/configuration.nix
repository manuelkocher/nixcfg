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
    ../../modules/mixins/gaming.nix
    ../../modules/mixins/desktop.nix
    ../../modules/mixins/git.nix
    ../../modules/mixins/audio.nix
    ../../modules/mixins/openssh.nix
    ../../modules/mixins/remote-store-cache.nix
    ./librewolf.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.edk2-uefi-shell.enable = false; # enable uefi shell

  # Create windows entry in systemd-boot menu
  # As seen in https://wiki.nixos.org/wiki/Dual_Booting_NixOS_and_Windows#systemd-boot_2
  # Boot into edk2 uefi shell and use "map -c" to show available disks and then "<DISK>:" and "ls EFI" to show the relevant contents
  boot.loader.systemd-boot.windows = {
    "windows" =
      let
        boot-drive = "FS1"; # edk2 device handle
      in
      {
        title = "Windows 11";
        efiDeviceHandle = boot-drive;
        sortKey = "y_windows"; # sort key; show near the bottom
      };
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

  programs.nix-ld.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # We have enough RAM
  zramSwap.enable = false;
}

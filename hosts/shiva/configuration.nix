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
    ../../modules/mixins/librewolf.nix
    ../../modules/mixins/dropbox.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "elan_i2c" ];

  # swap device
  boot.initrd.luks.devices."luks-e502d131-645e-4e13-8639-f91fc78167f7".device = "/dev/disk/by-uuid/e502d131-645e-4e13-8639-f91fc78167f7";

  networking.hostName = "shiva"; # Define your hostname.

  # Add the openconnect plugin for NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    wireshark
    stable.sage
  ];

  programs.nix-ld.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # We have enough RAM
  zramSwap.enable = true;
}

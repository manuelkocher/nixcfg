# TU "Guest" HP EliteBook Laptop 840 G5

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./disk-config.zfs.nix
      ../../modules/mixins/users.nix
      ../../modules/mixins/desktop.nix
      ../../modules/mixins/audio.nix
      ../../modules/mixins/jetbrains.nix
      ../../modules/mixins/openssh.nix
      ../../modules/mixins/remote-store-cache.nix
    ];

  # Bootloader.
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  boot.zfs.requestEncryptionCredentials = true;

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev"]; path = "/boot"; }
    ];
  };

  boot.initrd.network = {
    enable = true;
    postCommands = ''
      sleep 2
      zpool import -a;
    '';
  };

  users.users.${username}.initialPassword = username;

  networking = {
    hostId = "dddfda01";  # needed for ZFS
    hostName = "db01";
    networkmanager.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../apps/go-passbolt-cli/default.nix { })
  ];
}

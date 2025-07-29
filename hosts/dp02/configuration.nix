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
    ../../modules/mixins/jetbrains.nix
    ../../modules/mixins/openssh.nix
    ../../modules/mixins/remote-store-cache.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dp02"; # Define your hostname.

  # Add the openconnect plugin for NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    go-passbolt-cli
    zulip
  ];

  # env variables to prevent lagging in wayland
  # TODO remove after the bug has been fixed
  environment.variables = {
    GBM_BACKEND="nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME="nvidia";
    ENABLE_VKBASALT="1";
    LIBVA_DRIVER_NAME="nvidia";
    KWIN_DRM_USE_MODIFIERS="0";
  };

  # https://nixos.wiki/wiki/nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.nvidia.acceptLicense = true;
  hardware.graphics.enable = true;
  hardware.nvidia = {
    # https://github.com/NVIDIA/open-gpu-kernel-modules?tab=readme-ov-file#compatible-gpus
    open = false;

    # production: version 550
    # latest: version 560
    # set to beta to fix wayland lagging issues
    # TODO remove after bug has been fixed
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    #    # nvidia-drm.modeset=1 is required for some wayland compositors, e.g. sway
    modesetting.enable = true;
  };

  # disable GSP firmware to fix wayland lagging bug
  # TODO remove after bug has been fixed
  boot.kernelParams = [
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];

  # We have enough RAM
  zramSwap.enable = false;
}

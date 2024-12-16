{
  config,
  pkgs,
  inputs,
  ...
}:
{
  services.displayManager.defaultSession = "plasmax11";

  imports = [
    ./desktop-common.nix
    ./desktop-common-plasma6.nix
  ];

  environment.systemPackages = with pkgs; [
    xorg.xkill
  ];
}

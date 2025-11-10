{
  config,
  pkgs,
  inputs,
  lib,
  waylandSupport,
  ...
}:
{
  imports =
    lib.optional (!waylandSupport) ./desktop-x11.nix
    ++ lib.optional (waylandSupport) ./desktop-wayland.nix
    ++ [
      # Other imports here
    ];
}

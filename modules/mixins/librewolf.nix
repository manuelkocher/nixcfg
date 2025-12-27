{
  config,
  pkgs,
  inputs,
  userLogin,
  ...
}:
{
  home-manager.users.${userLogin} = {
    programs.librewolf = {
      enable = true;
      # see https://librewolf.net/docs/settings/
      settings = {
        "webgl.disabled" = false; # enable WebGL
        "privacy.resistFingerprinting" = true; # disable fingerprinting
        "privacy.clearOnShutdown.history" = true; # dont browser history on shutdown 
        "privacy.clearOnShutdown.cookies" = true; # clear cookies by default on shutdown
        "privacy.clearOnShutdown.downloads" = false; # dont clear downloads on shutdown
        "network.cookie.lifetimePolicy" = 2;
      };
      # Set per-site cookie permission
      "permissions.manager.permission.cookie" = {
        "https://play.qobuz.com/" = 1;  # Allow qobuz webplayer to store cookies
        "https://qobuz.com/" = 1; # Allow qobuz to store cookies
        "https://github.com/" = 1; # Allow github to store cookies
        "https://online.tugraz.at" = 1; # Allow TU Graz to store cookies
      };
    };
  };
}
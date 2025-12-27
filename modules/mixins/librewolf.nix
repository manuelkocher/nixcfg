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
        "privacy.clearOnShutdown.history" = false; # dont browser history on shutdown 
        "privacy.clearOnShutdown.cookies" = true; # clear cookies by default on shutdown
        "privacy.clearOnShutdown.downloads" = false; # dont clear downloads on shutdown
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = true; # newer version of cookie clearing? Not sure why there is an old one, this is the one that works
        "network.cookie.lifetimePolicy" = 2;
      };
    };
  };
}
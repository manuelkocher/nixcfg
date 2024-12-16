{
  lib,
  userLogin,
  useSecrets,
  ...
}:
{
  # https://mynixos.com/options/services.openssh
  services.openssh = {
    enable = true;
    openFirewall = lib.mkForce true;

    settings.X11Forwarding = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "no";

    # To use with nixos-anywhere you need to use this settings
    #    settings.PermitRootLogin = "yes";
    #    settings.PasswordAuthentication = true;

    extraConfig = ''StreamLocalBindUnlink yes'';
  };
}

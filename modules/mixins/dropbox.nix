{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{  
  systemd.user.services.dropbox = {
    description = "Dropbox";

    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      Restart = "on-failure";
    };
  };
}
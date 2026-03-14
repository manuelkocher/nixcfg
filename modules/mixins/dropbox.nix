{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    dropbox
  ];

  systemd.user.services.dropbox = {
    description = "Dropbox";

    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      Restart = "on-failure";
    };
  };
}
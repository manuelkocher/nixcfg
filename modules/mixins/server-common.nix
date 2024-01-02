{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./common.nix
  ];

  # https://mynixos.com/options/services.openssh
  services.openssh = {
    enable = true;
    openFirewall = lib.mkForce true;
    listenAddresses = [ { addr = "0.0.0.0"; port = 2222; } ];
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "no";
  };

  # https://nixos.wiki/wiki/Fail2ban
  services.fail2ban.enable = true;

  # Firewall
  # https://nixos.wiki/wiki/Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2222 ]; # SSH
  };

  nix = {
    settings = {
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };

  # https://rycee.gitlab.io/home-manager/options.html
  home-manager.users.omega = {
    programs.git = {
      enable = true;
      # use "git diff --no-ext-diff" for creating patches!
      difftastic.enable = true;
      userName  = "Patrizio Bekerle";
      userEmail = "patrizio@bekerle.com";
      ignores = [ ".idea" ".direnv" ];
    };
  };

  # Set empty password initially. Don't forget to set a password with "passwd".
  users.users.omega = {
    initialHashedPassword = "";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];
}

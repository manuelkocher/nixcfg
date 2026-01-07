{
  config,
  pkgs,
  inputs,
  xdg,
  userLogin,
  nix-jetbrains-plugins,
  system,
  useStableJetbrains,
  ...
}:
#{ config, inputs, xdg, ... }:

let
  #  jetbrainsPackages = if useStableJetbrains then pkgs.stable.jetbrains else pkgs.jetbrains;
  # Wait until 24.11 jetbrains work again
  # https://github.com/NixOS/nixpkgs/issues/358171
  jetbrainsPackages = pkgs.jetbrains;
in
## https://github.com/NixOS/nixpkgs/pull/309011
#  pkgs = import
#    (builtins.fetchTarball {
#      url = https://ghttps://plugins.jetbrains.com/plugin/17718-github-copilotithub.com/NixOS/nixpkgs/archive/c2fbe8c06eec0759234fce4a0453df200be021de.tar.gz;
#      sha256 = "sha256:1lhwzgzb0kr12903d1y5a2afghkknx9wgypisnnfz6xg2c6993wz";
#    })
#    {
#      config = config.nixpkgs.config;
#      localSystem = { system = "x86_64-linux"; };
#    };
{
  environment.systemPackages = with inputs.nix-jetbrains-plugins.lib."${system}"; [
    (buildIdeWithPlugins jetbrainsPackages "phpstorm" ["nix-idea"]) # add github copilot, see https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json and https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/applications/editors/jetbrains
  ];
  home-manager.users.${userLogin} = {
    xdg.desktopEntries = {
      phpstorm-nix-shell = {
        name = "PhpStorm with nix-shell";
        genericName = "Professional IDE for Web and PHP developers";
        comment = "PhpStorm provides an editor for PHP, HTML and JavaScript with on-the-fly code analysis, error prevention and automated refactorings for PHP and JavaScript code.";
        icon = "${jetbrainsPackages.phpstorm}/share/pixmaps/phpstorm.svg";
        exec = "nix-shell /home/${userLogin}/.shells/webdev.nix --run phpstorm";
        terminal = false;
        categories = [ "Development" ];
      };
    };
  };
}

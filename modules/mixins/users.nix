{
  lib,
  config,
  pkgs,
  inputs,
  userLogin,
  useSecrets,
  ...
}:

{
  # Set some fish config
  programs.fish = {
    shellAliases = {
      n18 = "nix-shell /home/${userLogin}/.shells/node18.nix --run fish";
      p8 = "nix-shell /home/${userLogin}/.shells/php8.nix --run fish";
      qtc = "nix-shell /home/${userLogin}/.shells/qt5.nix --run qtcreator";
      qtc6 = "nix-shell /home/${userLogin}/.shells/qt6.nix --run qtcreator";
      cl = "nix-shell /home/${userLogin}/.shells/qt5.nix --run clion";
      cl6 = "nix-shell /home/${userLogin}/.shells/qt6.nix --run clion";
      qmake5-path = "nix-shell /home/${userLogin}/.shells/qt5.nix --run \"whereis qmake\"";
      qmake6-path = "nix-shell /home/${userLogin}/.shells/qt6.nix --run \"whereis qmake\"";
      qce = "qc exec --command --color --atuin";
      qcel = "qc exec --command --color --atuin --last";
      qcs = "qc search --color";
      qcsw = "qc switch";
      pwdc = "pwd | xclip -sel clip";
      fwup = "fwupdmgr get-updates";
    };
    # TODO remove after https://github.com/NixOS/nixpkgs/issues/462025 is fixed
    interactiveShellInit = ''
        set -p fish_complete_path ${pkgs.fish}/share/fish/completions
      '';
  };
}

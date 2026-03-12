{
  config,
  pkgs,
  inputs,
  userLogin,
  ...
}:
{
  home-manager.users.${userLogin} = {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
    };
  };
}
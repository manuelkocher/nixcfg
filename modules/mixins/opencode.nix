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
      settings = {
        provider = {
          "azure-anthropic" = {
            name = "Azure AI Foundry (Anthropic)";
            npm = "@ai-sdk/anthropic";
            api = "https://{env:AZURE_RESOURCE_NAME}.services.ai.azure.com/anthropic/v1";
            models = {
              "claude-opus-4-6" = {
                id = "claude-opus-4-6";
                name = "Claude Opus 4.6";
                tool_call = true;
                attachment = true;
                reasoning = true;
                temperature = true;
              };
              "claude-sonnet-4-6" = {
                id = "claude-sonnet-4-6";
                name = "Claude Sonnet 4.6";
                tool_call = true;
                attachment = true;
                reasoning = true;
                temperature = true;
              };
            };
          };
        };
      };
    };
  };
}
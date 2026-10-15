# vscode.nix — NixOS module: VS Code with a fixed extension set and Java support.
#
# Usage (configuration.nix):
#   imports = [ ./vscode.nix ];
#   programs.vscode-custom.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.vscode-custom;

  vscode = pkgs.vscode-with-extensions.override {
    vscodeExtensions = with pkgs.vscode-extensions; [
      # Requested extensions
      anthropic.claude-code
      streetsidesoftware.code-spell-checker # base extension the German dictionary depends on
      streetsidesoftware.code-spell-checker-german
      bbenoist.nix

      # Java support (the individual parts of the "Extension Pack for Java")
      redhat.java                    # language server: completion, diagnostics, refactoring
      vscjava.vscode-java-debug      # debugger
      vscjava.vscode-java-test       # JUnit / TestNG runner
      vscjava.vscode-java-dependency # project & dependency explorer
      vscjava.vscode-maven           # Maven integration
      vscjava.vscode-gradle          # Gradle integration
    ];
  };
in
{
  options.programs.vscode-custom = {
    enable = lib.mkEnableOption "VS Code with Claude Code, German spell checking, Nix and Java support";

    jdk = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk25;
      defaultText = lib.literalExpression "pkgs.jdk25";
      description = "JDK used for Java development. The Java language server needs JDK 17 or newer.";
    };
  };

  config = lib.mkIf cfg.enable {
    # VS Code and the Claude Code extension are unfree.
    # If you already set allowUnfreePredicate elsewhere, merge these names into it instead.
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "vscode"
        "vscode-with-extensions"
        "vscode-extension-anthropic-claude-code"
      ];

    # Installs the JDK and sets JAVA_HOME system-wide, which redhat.java picks up.
    programs.java = {
      enable = true;
      package = cfg.jdk;
    };

    environment.systemPackages = [
      vscode
      pkgs.maven
      pkgs.gradle
    ];
  };
}

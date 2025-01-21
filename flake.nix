{
  description = "mkocher's machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    #    nixinate.url = "github:matthewcroughan/nixinate";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    #    robotnix.url = "github:danielfullmer/robotnix";
    pia.url = "github:pia-foss/manual-connections";
    pia.flake = false;
    catppuccin.url = "github:catppuccin/starship";
    catppuccin.flake = false;
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      #      , nixinate
      home-manager,
      nixpkgs,
      nixpkgs-stable,
      pia,
      catppuccin,
      disko,
      nixos-hardware,
      plasma-manager,
      #      , robotnix
      ...
    }@inputs:

    let
      system = "x86_64-linux";
      overlays-nixpkgs = final: prev: {
        stable = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
      commonServerModules = [
        home-manager.nixosModules.home-manager
        { }
        (
          { ... }:
          {
            nixpkgs.overlays = [ overlays-nixpkgs ];
          }
        )
      ];
      commonDesktopModules = [
        home-manager.nixosModules.home-manager
        { home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ]; }
        (
          { ... }:
          {
            nixpkgs.overlays = [ overlays-nixpkgs ];
          }
        )
      ];
    in
    {
      #     config = nixpkgs.config.systems.${builtins.currentSystem}.config;
      #     hostname = config.networking.hostName;
      #    nixosModules = import ./modules { inherit (nixpkgs) lib; };
      commonArgs = {
        userLogin = "mkocher";
        userNameLong = "Manuel Kocher";
        userNameShort = "Manuel";
        userEmail = "manuel.kocher@tugraz.at";
      };

      nixosConfigurations = {
        # TU ThinkBook
        dp02 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonDesktopModules ++ [
            ./hosts/dp02/configuration.nix
            ./hosts/dp02/hardware-configuration.nix
          ];
          specialArgs = self.commonArgs // {
            inherit inputs;
            userLogin = "mkocher";
            userNameLong = "Manuel Kocher";
            userNameShort = "Manuel";
            userEmail = "manuel.kocher@tugraz.at";
            useSecrets = false;
          };
        };
      };
    };
}

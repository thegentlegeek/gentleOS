# Helper functions for NixOS flake configuration
{ inputs, ... }:

{
  # Create a NixOS system configuration
  # Usage: mkHost { hostname = "zbook"; extraModules = [ ... ]; }
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    nixpkgs ? inputs.nixpkgs,
    extraModules ? []
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ../hosts/${hostname}
      ] ++ extraModules;
    };

  # Create a Home Manager configuration
  # Usage: mkHome { username = "justin"; }
  mkHome = {
    username,
    system ? "x86_64-linux"
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        inherit inputs;
        stylix = inputs.stylix;
      };
      modules = [
        ../users/${username}/home.nix
        ({ ... }: { nixpkgs.config.allowUnfree = true; })
      ];
    };
}

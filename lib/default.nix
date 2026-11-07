# Helper functions for NixOS flake configuration
{ inputs, ... }:

{
  # A NixOS system on gentleOS's pinned inputs, from your own modules.
  # Usage: gentleOS.lib.mkSystem { modules = [ gentleOS.nixosModules.desktop ./hosts/laptop ]; }
  mkSystem = {
    system ? "x86_64-linux",
    nixpkgs ? inputs.nixpkgs,
    modules ? [],
    specialArgs ? {}
  }:
    nixpkgs.lib.nixosSystem {
      inherit system modules;
      specialArgs = specialArgs // { gentleInputs = inputs; };
    };

  # A standalone Home Manager configuration on gentleOS's pinned inputs.
  # Usage: gentleOS.lib.mkHomeConfig { modules = [ gentleOS.homeModules.desktop ./home.nix ]; }
  mkHomeConfig = {
    system ? "x86_64-linux",
    modules ? [],
    specialArgs ? {}
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = specialArgs // { gentleInputs = inputs; };
      modules = modules ++ [
        ({ ... }: { nixpkgs.config.allowUnfree = true; })
      ];
    };
}

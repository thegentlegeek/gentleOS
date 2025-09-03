{
  description = "My modular NixOS with Home Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Wallpaper (auto colorized wallpaper that I will attempt to further automate based on Stylix theme chosen)
    nix-wallpaper = {
      url = "github:lunik1/nix-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { 
    self,
    nixpkgs,
    unstable,
    home-manager,
    stylix,
    nix-wallpaper
    ...
    } 
    @ inputs: 
  let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      # Host configuration for zbook (laptop)
      zbook = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/zbook
          ./modules/workstation
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for testing (steambox)
      testing = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/testing
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for Nixcloud (git server on Linode)
      nixcloud = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/nixcloud
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for Geigcraft server
      geigcraft-server = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/geigcraft-server
          inputs.stylix.nixosModules.stylix
        ];
      };
    };

    # Standalone Home Manager configuration
    homeConfigurations = {
      "justin" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { 
          inherit inputs outputs; 
          stylix = inputs.stylix;  
        };
        modules = [ 
          ./home/users/justin 
          ({ config, pkgs, ... }: {
            nixpkgs.config.allowUnfree = true;
          })
        ];
      };
    };
  };
}

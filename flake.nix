{
  description = "My modular NixOS with Home Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:danth/stylix/release-25.11";
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
    nix-wallpaper,
    ...
    } 
    @ inputs: 
  let
    inherit (self) outputs;
    lib = import ./lib { inherit inputs; };
  in {
    nixosConfigurations = {
      # Host configuration for zbook (laptop)
      zbook = lib.mkHost {
        hostname = "zbook";
        extraModules = [
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for testing (steambox)
      testing = lib.mkHost {
        hostname = "testing";
        extraModules = [
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for Nixcloud (git server on Linode)
      nixcloud = lib.mkHost {
        hostname = "nixcloud";
        extraModules = [
          inputs.stylix.nixosModules.stylix
        ];
      };

      # Host configuration for Geigcraft server (uses unstable for latest minecraft-server)
      geigcraft-server = lib.mkHost {
        hostname = "geigcraft-server";
        nixpkgs = unstable;
      };
    };

    # Standalone Home Manager configuration
    homeConfigurations = {
      "justin" = lib.mkHome {
        username = "justin";
      };
    };
  };
}

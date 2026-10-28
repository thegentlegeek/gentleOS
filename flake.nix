{
  description = "My modular NixOS with Home Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Wallpaper (auto colorized wallpaper that I will attempt to further automate based on Stylix theme chosen)
    nix-wallpaper = {
      url = "github:lunik1/nix-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM Agents (opencode, claude-code, claude-desktop and other AI tools)
    # Intentionally does NOT follow our nixpkgs: upstream only tests against its
    # own pinned nixpkgs-unstable, and using its pin lets us hit cache.numtide.com.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Hyprland, pinned to an upstream RELEASE tag (not main). Bump the tag here
    # (and on hyprland-plugins below) to upgrade; `nix flake update` won't move it.
    # Intentionally does NOT follow our nixpkgs so Mesa and the build match
    # upstream's tested set and the hyprland.cachix.org cache.
    # Hyprland, pinned to an upstream RELEASE tag (not main). Bump the tag here and on
    # hyprland-plugins below to upgrade; `nix flake update` won't move a tag.
    # Intentionally does NOT follow our nixpkgs: the build then matches upstream's
    # tested set and hyprland.cachix.org (Mesa is matched in the NixOS module).
    # 0.57+ reads only Lua configs (hyprland.lua).
    hyprland.url = "github:hyprwm/Hyprland/v0.57.0";

    # Hyprland plugins: built against the exact same Hyprland as above via `follows`.
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/v0.57.0";
      inputs.hyprland.follows = "hyprland";
    };
  };

  # Caches for `nix build`/`nix run` outside NixOS (hosts get these from modules/nixos/base.nix)
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  outputs = { 
    self,
    nixpkgs,
    unstable,
    home-manager,
    stylix,
    nix-wallpaper,
    llm-agents,
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

    # `nix flake check`: validates generated configs (see checks/default.nix)
    checks.x86_64-linux = import ./checks {
      inherit self;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    };

    # `nix fmt`
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
  };
}

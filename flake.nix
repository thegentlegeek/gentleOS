{
  description = "A NixOS desktop on Hyprland, themed end to end from one color scheme";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.tinted-schemes.follows = "tinted-schemes";
    };

    # base16/base24 color schemes straight from upstream, instead of nixpkgs'
    # base16-schemes snapshot. `nix flake update tinted-schemes` picks up newly
    # added schemes (the repo's default branch is spec-0.11).
    tinted-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };

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

  # Prebuilt Hyprland for `nix build` and `nix flake check` (hosts get it from
  # modules/nixos/window-managers/hyprland)
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  outputs = {
    self,
    nixpkgs,
    ...
    }
    @ inputs:
  let
    inherit (self) outputs;
    lib = import ./lib { inherit inputs; };
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    wallpapers = import ./pkgs/wallpapers { inherit pkgs; };
    # A tinted-schemes scheme ("base16/nord") as Stylix reads it: base16.nix's
    # mkSchemeAttrs, so the palette matches config.lib.stylix.colors.
    base16 = inputs.stylix.inputs.base16.lib { inherit pkgs; inherit (pkgs) lib; };
    schemeAttrs = path: base16.mkSchemeAttrs "${inputs.tinted-schemes}/${path}.yaml";
  in {
    # For your own flake: see lib/default.nix.
    inherit lib;
    nixosModules.desktop = ./modules/nixos/profiles/desktop.nix;
    nixosModules.amd = ./modules/nixos/hardware/amd.nix;
    nixosModules.intel = ./modules/nixos/hardware/intel.nix;
    homeModules.desktop = ./modules/home/profiles/desktop.nix;

    # `nix flake init -t github:thegentlegeek/gentleOS`
    templates.default = {
      path = ./templates/default;
      description = "Your own config on the gentleOS desktop";
      welcomeText = "Next: follow Getting Started in the gentleOS README.";
    };

    # A minimal host and user for the checks in checks/
    nixosConfigurations.demo = lib.mkSystem { modules = [ ./hosts/demo ]; };
    homeConfigurations.demo = lib.mkHomeConfig { modules = [ ./users/demo/home.nix ]; };

    # Every wallpaper in every scheme, built on demand without evaluating a
    # whole system or home: `nix build .#wallpapers.<name>.<system>.<scheme>`,
    # e.g. .#wallpapers.contours.base16.nord. Tune them in pkgs/wallpapers.
    legacyPackages.x86_64-linux.wallpapers = nixpkgs.lib.genAttrs wallpapers.names (name:
      nixpkgs.lib.genAttrs [ "base16" "base24" ] (system:
        nixpkgs.lib.mapAttrs' (file: _: let scheme = nixpkgs.lib.removeSuffix ".yaml" file; in {
          name = scheme;
          value = wallpapers.render { inherit name; palette = schemeAttrs "${system}/${scheme}"; };
        }) (builtins.readDir "${inputs.tinted-schemes}/${system}")));

    # `nix flake check`: validates generated configs (see checks/default.nix)
    checks.x86_64-linux = import ./checks { inherit self pkgs; };

    # `nix fmt`
    formatter.x86_64-linux = pkgs.nixfmt;

    # `nix develop`: the tools for working on this repo.
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [
        pkgs.nixfmt
        pkgs.nil
        inputs.home-manager.packages.x86_64-linux.default
      ];
    };
  };
}

{
  description = "My gentleOS configuration";

  # Prebuilt Hyprland. Accept this when asked, or Hyprland compiles locally.
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  inputs.gentleOS.url = "github:thegentlegeek/gentleOS";

  outputs = { gentleOS, ... }:
    let
      # Change these two. username has to be the account you're logged in as now.
      # The theme picker builds the configurations named after them.
      hostname = "my-computer";
      username = "me";
      specialArgs = { inherit hostname username; };
    in
    {
      nixosConfigurations.${hostname} = gentleOS.lib.mkSystem {
        inherit specialArgs;
        modules = [
          gentleOS.nixosModules.desktop
          gentleOS.nixosModules.amd # or intel, which nothing tests yet
          ./hardware-configuration.nix
          ./host.nix
        ];
      };

      homeConfigurations.${username} = gentleOS.lib.mkHomeConfig {
        inherit specialArgs;
        modules = [
          gentleOS.homeModules.desktop
          ./home.nix
        ];
      };

      # The theme picker builds wallpapers from here.
      legacyPackages = gentleOS.legacyPackages;
    };
}

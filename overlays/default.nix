# Overlay definitions
# This file can be used to define custom overlays for the flake.
# 
# Example usage in flake.nix:
#   nixpkgs.overlays = [ (import ./overlays) ];
#
# Example overlay for unstable packages:
#   final: prev: {
#     unstable = import inputs.unstable {
#       system = final.system;
#       config.allowUnfree = true;
#     };
#   }

final: prev: {
  # Add custom overlays here
}

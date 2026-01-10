# Custom packages
# This directory can be used to define custom packages for the flake.
#
# Example usage:
#   myPackage = pkgs.callPackage ./my-package { };
#
# Directory structure:
#   pkgs/
#   ├── default.nix       (this file)
#   └── my-package/
#       └── default.nix   (package definition)

{ pkgs, ... }:

{
  # Add custom packages here
  # example = pkgs.callPackage ./example { };
}

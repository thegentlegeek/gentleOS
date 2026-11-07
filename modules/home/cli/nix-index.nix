{ 
  lib,
  ... 
}:

{
  programs.nix-index = {
    enable = lib.mkDefault true;
  };
}
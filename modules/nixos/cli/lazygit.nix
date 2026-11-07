{ 
  lib,
  ... 
}:

{
  programs.lazygit = {
    enable = lib.mkDefault true;
  };
}
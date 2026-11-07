{ 
  lib,
  ... 
}:

{
  programs.tmux = {
    enable = lib.mkDefault true;
    keyMode = lib.mkDefault "vi";
    };
}
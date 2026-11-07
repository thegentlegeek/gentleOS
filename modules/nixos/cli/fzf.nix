{ 
  lib,
  pkgs,
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    fzf
  ];

  programs.fzf = {
    keybindings = lib.mkDefault true;
    fuzzyCompletion = lib.mkDefault true;
  };
}
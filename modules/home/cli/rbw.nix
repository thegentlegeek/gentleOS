{
  lib,
  pkgs,
  ...
}:

{
  programs.rbw = {
    enable = true;
    settings = {
      email = "justin@geigley.com";
      # The desktop shell sets its own (window-managers/hyprland/quickshell).
      pinentry = lib.mkDefault pkgs.pinentry-tty;
    };
  };
}

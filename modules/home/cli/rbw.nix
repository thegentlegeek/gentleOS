{
  lib,
  pkgs,
  ...
}:

{
  programs.rbw = {
    enable = true;
    settings = {
      # Set programs.rbw.settings.email where you import this.
      # The desktop shell sets its own (window-managers/hyprland/quickshell).
      pinentry = lib.mkDefault pkgs.pinentry-tty;
    };
  };
}

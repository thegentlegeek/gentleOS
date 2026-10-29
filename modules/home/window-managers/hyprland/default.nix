{
  lib,
  ...
}:


{
  imports =
    [
      ./hyprland-config.nix
      ./quickshell
      ./waybar
      ./rofi.nix
      ./dunst.nix
      ./hypridle.nix
    ];

  # Which desktop shell draws the bar and notifications. Both are kept while the
  # Quickshell shell is being built out; switching is a rebuild, nothing else.
  options.gentleOS.desktopShell = lib.mkOption {
    type = lib.types.enum [ "quickshell" "waybar" ];
    default = "quickshell";
    description = ''
      "quickshell": Quickshell bar, quick settings and notification center (./quickshell).
      "waybar": Waybar + dunst (./waybar, ./dunst.nix).
    '';
  };

  # Browser profiles, used by the SUPER+B binds and the launcher's web search.
  options.gentleOS.browser = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = {
      personal = [ "chromium" "--profile-directory=Profile 2" ];
      work = [ "chromium" "--profile-directory=Profile 3" ];
    };
    description = "argv of the browser for each profile (personal, work).";
  };
}

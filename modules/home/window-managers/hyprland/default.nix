{
  lib,
  ...
}:


{
  imports =
    [
      ./hyprland-config.nix
      ./quickshell
      ./hypridle.nix
    ];

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

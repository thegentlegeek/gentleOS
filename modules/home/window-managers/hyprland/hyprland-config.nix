{
  pkgs,
  inputs,
  ...
}:
let
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  qt = {
    enable = true;
    style.name = "breeze";
    platformTheme.name = "adwaita";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Lua config (required from Hyprland 0.57). The config itself lives in
    # ./hyprland.lua as native Lua; Stylix contributes colors via `settings`.
    configType = "lua";
    # The NixOS module (programs.hyprland) installs the compositor and portal from
    # the upstream flake; HM only writes config so we don't pull a second Hyprland.
    package = null;
    portalPackage = null;
    systemd.enable = true;
    # Built against the pinned Hyprland via `follows` in flake.nix.
    plugins = [
      hyprlandPlugins.hyprfocus
    ];
    extraConfig = builtins.readFile ./hyprland.lua;
  };

  # Polkit agent (Hyprland's own). User service on graphical-session.target, which
  # UWSM provides; finds the session via logind, so no XDG_SESSION_ID needed.
  services.hyprpolkitagent.enable = true;
}

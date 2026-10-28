{
  config,
  pkgs,
  inputs,
  ...
}:
let
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Lua config (required from Hyprland 0.57). The config itself lives in
    # ./hyprland.lua as native Lua; Stylix contributes colors via `settings`.
    configType = "lua";
    # The NixOS module (programs.hyprland) installs the compositor and portal from
    # the upstream flake; HM only writes config so we don't pull a second Hyprland.
    package = null;
    portalPackage = null;
    # UWSM owns the session: it exports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE
    # to systemd and drives graphical-session.target, so HM's duplicate
    # hyprland-session.target and activation-env exec are not needed.
    systemd.enable = false;
    # Built against the pinned Hyprland via `follows` in flake.nix.
    plugins = [
      hyprlandPlugins.hyprfocus
    ];
    extraConfig = builtins.readFile ./hyprland.lua;
  };

  # Session environment, loaded by UWSM before the compositor starts and exported
  # to Hyprland, the apps it launches, and systemd user units (waybar, dunst...).
  # Sourcing hm-session-vars is what makes home.sessionVariables (NIXOS_OZONE_WL,
  # XCURSOR_*, Qt theme) reach the session at all: no HM-managed shell loads it.
  xdg.configFile."uwsm/env".text = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export MOZ_ENABLE_WAYLAND=1
  '';
  xdg.configFile."uwsm/env-hyprland".text = ''
    export HYPRCURSOR_SIZE=${toString config.stylix.cursor.size}
  '';

  # Clipboard history (text + images), as user services instead of compositor
  # autostart so they restart on crash.
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # Polkit agent (Hyprland's own). User service on graphical-session.target, which
  # UWSM provides; finds the session via logind, so no XDG_SESSION_ID needed.
  services.hyprpolkitagent.enable = true;
}

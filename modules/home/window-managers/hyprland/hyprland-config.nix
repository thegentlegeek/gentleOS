{
  ...
}:

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
    systemd.enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
  };
}

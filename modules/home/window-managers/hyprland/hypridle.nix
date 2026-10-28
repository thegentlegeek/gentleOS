{
  config,
  lib,
  pkgs,
  ...
}:

let
  brightnessctl = lib.getExe pkgs.brightnessctl;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  # Hyprland 0.57+ (Lua config): `hyprctl dispatch` takes a Lua dispatcher.
  dpms = state: ''hyprctl dispatch 'hl.dsp.dpms({ action = "${state}" })' '';
in
{
  # Idle: dim -> lock -> screen off -> suspend. Lock also runs before any sleep
  # (lid close included, via logind).
  #
  # Overriding auto-lock: hypridle honours Wayland, D-Bus and systemd idle
  # inhibitors (ignore_*_inhibit default to false), so
  #   - the Waybar idle_inhibitor button toggles it manually,
  #   - fullscreen windows inhibit it (window rule in hyprland.lua),
  #   - apps that ask (video in browsers, mpv, calls) inhibit it.
  # Inhibitors do not stop lid-close suspend; that always locks and sleeps.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Don't stack lock screens if one is already up.
        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${hyprlock}";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = dpms "on";
      };

      listener = [
        {
          timeout = 150;
          on-timeout = "${brightnessctl} -s set 10";
          on-resume = "${brightnessctl} -r";
        }
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
        {
          # Same action as closing the lid (logind lidSwitch).
          timeout = 1800;
          on-timeout = "systemctl suspend-then-hibernate";
        }
      ];
    };
  };
}

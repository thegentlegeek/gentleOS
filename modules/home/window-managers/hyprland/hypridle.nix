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
  suspend = lib.getExe (import ./suspend.nix { inherit pkgs; });
in
{
  # hypridle locks with hyprlock, which exits at once without this module's
  # config, leaving the screen unlocked.
  programs.hyprlock.enable = true;

  # Idle: dim -> lock -> screen off -> suspend. Lock also runs before any sleep
  # (lid close included, via logind).
  #
  # Overriding auto-lock: hypridle honours Wayland, D-Bus and systemd idle
  # inhibitors (ignore_*_inhibit default to false), so
  #   - Quick settings > Keep awake (or SUPER+SHIFT+I) toggles it; the bar
  #     shows an eye while it's on,
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

      listener = lib.optional (config.gentleOS.idleDimSeconds != null) {
        timeout = config.gentleOS.idleDimSeconds;
        on-timeout = "${brightnessctl} -s set 10";
        on-resume = "${brightnessctl} -r";
      } ++ lib.optional (config.gentleOS.idleLockSeconds != null) {
        timeout = config.gentleOS.idleLockSeconds;
        on-timeout = "loginctl lock-session";
      } ++ lib.optional (config.gentleOS.idleScreenOffSeconds != null) {
        timeout = config.gentleOS.idleScreenOffSeconds;
        on-timeout = dpms "off";
        on-resume = dpms "on";
      } ++ lib.optional (config.gentleOS.idleSuspendSeconds != null) {
        # Same action as closing the lid (logind HandleLidSwitch).
        timeout = config.gentleOS.idleSuspendSeconds;
        on-timeout = suspend;
      };
    };
  };
}

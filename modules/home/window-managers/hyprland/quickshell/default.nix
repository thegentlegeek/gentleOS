{
  config,
  lib,
  pkgs,
  ...
}:

let
  exe = lib.getExe;
  stylix = config.stylix;
  colors = config.lib.stylix.colors.withHashtag;

  # Quickshell turns `Name.qml.json` files in the config into read-only QML
  # singletons, so the Nix side hands values over as plain JSON.
  theme = {
    # base00..base0F from the Stylix scheme.
    colors = lib.genAttrs (map (i: "base0${i}") [
      "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F"
    ]) (name: colors.${name});
    fontMono = stylix.fonts.monospace.name;
    fontSans = stylix.fonts.sansSerif.name;
    # Stylix sizes are points; the bar keeps Waybar's 15px.
    fontSizeBar = 15;
    fontSizePopups = stylix.fonts.sizes.popups;
    # Background alpha of the bar and of popups/panels (blurred, hyprland.lua).
    barAlpha = 0.8;
    popupAlpha = 0.85;
    radius = 10;
  };

  # GUI apps go through `uwsm app` so they get their own systemd scope instead
  # of living (and dying) in quickshell's cgroup.
  app = cmd: [ (exe pkgs.uwsm) "app" "--" ] ++ cmd;

  settings = {
    lock = [ "loginctl" "lock-session" ];
    logout = [ (exe pkgs.uwsm) "stop" ];
    # Same action as closing the lid / hypridle's long timeout.
    suspend = [ "systemctl" "suspend-then-hibernate" ];
    reboot = [ "systemctl" "reboot" ];
    poweroff = [ "systemctl" "poweroff" ];
    audioSettings = app [ (exe pkgs.pavucontrol) ];
    bluetoothSettings = app [ "${pkgs.blueman}/bin/blueman-manager" ];
    networkSettings = app [ "${pkgs.networkmanagerapplet}/bin/nm-connection-editor" ];
    brightnessctl = exe pkgs.brightnessctl;
    # For the few sysfs globs QML can't do itself (hwmonN, keyboard LEDs).
    sh = pkgs.runtimeShell;
    # k10temp (Tctl) via its PCI function address, which is stable across boots;
    # the hwmonN directory under it is not. The module hides itself if missing.
    tempHwmonDir = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
    tempInput = "temp1_input";
    tempCritical = 90;
  };

  shellConfig = pkgs.runCommandLocal "quickshell-gentle" { } ''
    cp -r ${./shell} $out
    chmod u+w $out
    cp ${pkgs.writeText "Theme.qml.json" (builtins.toJSON theme)} $out/Theme.qml.json
    cp ${pkgs.writeText "Settings.qml.json" (builtins.toJSON settings)} $out/Settings.qml.json
  '';
in
{
  config = lib.mkIf (config.gentleOS.desktopShell == "quickshell") {
    programs.quickshell = {
      enable = true;
      configs.gentle = shellConfig;
      activeConfig = "gentle";
      systemd = {
        enable = true;
        # UWSM drives graphical-session.target (hyprland-config.nix).
        target = "graphical-session.target";
      };
    };

    # Stop with the session (UWSM stops graphical-session.target on logout).
    systemd.user.services.quickshell.Unit.PartOf = [ "graphical-session.target" ];
  };
}

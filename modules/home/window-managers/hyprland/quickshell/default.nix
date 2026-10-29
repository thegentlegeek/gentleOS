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
    # The "Propo" variant of the same Nerd Font: text glyphs are identical, but
    # icons keep their natural size and advance width ("Mono" squeezes them to
    # one cell; plain "Nerd Font" draws them wide but overlaps the next glyph).
    # Used for all shell text.
    fontShell = lib.removeSuffix " Mono" stylix.fonts.monospace.name + " Propo";
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

  # Emoji, Nerd Font glyphs and symbols for the launcher's "." mode
  # (LauncherEmoji.qml), built from Unicode, CLDR and Nerd Fonts data.
  nerdFontsVersion = lib.head (lib.splitString "+" pkgs.nerd-fonts.jetbrains-mono.version);
  glyphNames = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v${nerdFontsVersion}/glyphnames.json";
    hash = "sha256-4tENI/W/8L1vBnbpsB2XifzcZW3ntJiilVwncW6kQ5w=";
  };
  cldr = "${pkgs.cldr-annotations}/share/unicode/cldr/common";
  emojiData = pkgs.runCommandLocal "gentle-emoji.json" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 -I ${./emoji.py} \
      ${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt \
      ${cldr}/annotations/en.xml ${cldr}/annotationsDerived/en.xml \
      ${glyphNames} > $out
  '';

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
    # CPU and temperature only appear on the bar at or above these.
    tempWarn = 80;
    cpuWarn = 0.8;
    # Tray items hidden from the bar, matched against the item's id/title
    # (case-insensitive). blueman-applet keeps running as the pairing agent;
    # Bluetooth is managed from quick settings.
    trayHidden = [ "blueman" ];

    # Launcher (LauncherState.qml). Apps start as `uwsm app -- <id>.desktop`.
    uwsm = exe pkgs.uwsm;
    cliphist = exe pkgs.cliphist;
    wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
    qalc = "${pkgs.libqalculate}/bin/qalc";
    # Run mode reads its history and runs commands in it.
    fish = exe config.programs.fish.package;
    emojiData = "${emojiData}";
    terminal = [ (exe pkgs.kitty) ];
    browserPersonal = app config.gentleOS.browser.personal;
    browserWork = app config.gentleOS.browser.work;
    # %s is the URL-encoded query.
    searchUrl = "https://www.google.com/search?q=%s";
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

    systemd.user.services.quickshell.Unit = {
      # Stop with the session (UWSM stops graphical-session.target on logout).
      PartOf = [ "graphical-session.target" ];
      # Restart on `home-manager switch` when the config changes: the running
      # shell keeps watching the old store path and never reloads by itself.
      X-Restart-Triggers = [ "${shellConfig}" ];
    };
  };
}

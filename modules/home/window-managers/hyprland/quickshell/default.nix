{
  config,
  gentleInputs,
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
  # The active theme, for the shell (Theme.qml.json) and for what outlives this
  # generation: the theme picker and gentle-theme read gentle-theme/current.json.
  theme = {
    inherit (config.gentleOS.theme) scheme wallpaper;
    image = lib.mapNullable toString config.gentleOS.theme.image;
    # base00..base0F from the Stylix scheme.
    colors = lib.genAttrs (map (i: "base0${i}") [
      "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F"
    ]) (name: colors.${name});
    fontMono = stylix.fonts.monospace.name;
    # Used for all shell text. The default is the "Propo" variant of a Nerd Font:
    # icons keep their natural size and advance width ("Mono" squeezes them to
    # one cell; plain "Nerd Font" draws them wide but overlaps the next glyph).
    fontShell = config.gentleOS.shellFont.name;
    fontSans = stylix.fonts.sansSerif.name;
    # In pixels, where Stylix's sizes are points: 15px at its default of 10.
    fontSizeBar = builtins.ceil (1.5 * stylix.fonts.sizes.desktop);
    fontSizePopups = stylix.fonts.sizes.popups;
    # Background alpha of the bar and of popups/panels (blurred, hyprland.lua).
    # The bar shares the terminal's, so kitty's glass matches it.
    barAlpha = stylix.opacity.terminal;
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

  # pinentry for rbw/gpg: the shell's prompt (shell/Pinentry.qml) through its
  # socket, or pinentry-tty without a graphical session or a running shell.
  # The probe connects without touching stdin, so the fallback still gets the
  # whole conversation.
  #
  # rbw closes stdin right after GETPIN, before reading the answer. Passed on
  # as is, that EOF closes the socket and the prompt with it, so it becomes a
  # BYE instead (the shell runs it once the prompt is answered) and socat
  # neither shuts the socket down nor gives up while the prompt is open.
  pinentry = pkgs.writeShellApplication {
    name = "pinentry-gentle";
    runtimeInputs = [ pkgs.socat pkgs.pinentry-tty ];
    text = ''
      sock="''${XDG_RUNTIME_DIR:-}/gentle-pinentry.sock"
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "$sock" ] && socat -u OPEN:/dev/null UNIX-CONNECT:"$sock" 2>/dev/null; then
        { cat; echo BYE; } | socat -t 86400 STDIO UNIX-CONNECT:"$sock",shut-none 2>/dev/null || true
        exit 0
      fi
      exec pinentry-tty "$@"
    '';
  };

  # Run by gentle-theme keep through pkexec (as root, after the polkit prompt):
  # switch to a NixOS system it already built, as nixos-rebuild switch does.
  # Only a nixos-system store path is accepted.
  switchSystem = pkgs.writeShellScript "gentle-theme-switch-system" ''
    set -eu
    [[ $1 =~ ^/nix/store/[a-z0-9]{32}-nixos-system-[^/]+$ && -x $1/bin/switch-to-configuration ]] \
      || { echo "not a NixOS system: $1" >&2; exit 1; }
    /run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --set "$1"
    # In its own unit, like nixos-rebuild, so restarted services can't take it down.
    exec ${pkgs.systemd}/bin/systemd-run --collect --pipe --wait --quiet --service-type=exec \
      --unit gentle-theme-switch-to-configuration "$1/bin/switch-to-configuration" switch
  '';

  # `gentle-theme`: preview, keep or revert a theme (./theme.sh).
  gentleTheme = pkgs.writeShellApplication {
    name = "gentle-theme";
    runtimeInputs = with pkgs; [ coreutils gawk git jq libnotify openssh systemd uwsm ];
    runtimeEnv = {
      SWITCH_SYSTEM = switchSystem;
      DEFAULT_FLAKE = config.gentleOS.flakePath;
      # The theme file's path inside the flake, which Nix copied to the store whole.
      THEME_FILE = lib.head (builtins.match "/nix/store/[^/]+/(.*)" (toString config.gentleOS.themeFile));
      QUICKSHELL = exe config.programs.quickshell.package;
      # Through the config's link, not the store path: shellConfig depends on this package.
      THEME_PICKER = "${config.xdg.configHome}/quickshell/gentle/theme-picker.qml";
    };
    text = builtins.readFile ./theme.sh;
  };

  # Every scheme the theme picker offers, A-Z with base16 first on a shared name.
  # Only .yaml files: that's what Stylix and the flake's wallpapers read.
  schemeCatalog = pkgs.runCommandLocal "ThemeSchemes.qml.json" { nativeBuildInputs = with pkgs; [ jq yq-go ]; } ''
    cd ${gentleInputs.tinted-schemes}
    yq -o=json -I=0 '.id = filename' base16/*.yaml base24/*.yaml | jq -s '{
      schemes: map({
        id: .id | rtrimstr(".yaml"),
        variant,
        colors: .palette | with_entries(select(.key | test("^base0")))
      }) | sort_by(.id | split("/") | reverse)
    }' >$out
  '';

  browser = if config.gentleOS.browser.personal != null then config.gentleOS.browser.personal else [ "${pkgs.xdg-utils}/bin/xdg-open" ];

  settings = {
    lock = [ "loginctl" "lock-session" ];
    logout = [ (exe pkgs.uwsm) "stop" ];
    # Same action as closing the lid / hypridle's long timeout.
    suspend = [ (exe (import ../suspend.nix { inherit pkgs; })) ];
    reboot = [ "systemctl" "reboot" ];
    poweroff = [ "systemctl" "poweroff" ];
    audioSettings = app [ (exe pkgs.pavucontrol) ];
    bluetoothSettings = app [ "${pkgs.blueman}/bin/blueman-manager" ];
    networkSettings = app [ "${pkgs.networkmanagerapplet}/bin/nm-connection-editor" ];
    brightnessctl = exe pkgs.brightnessctl;
    # For the few sysfs globs QML can't do itself (hwmonN, keyboard LEDs).
    sh = pkgs.runtimeShell;
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
    browserPersonal = app browser;
    browserWork = app (if config.gentleOS.browser.work != null then config.gentleOS.browser.work else browser);
    inherit (config.gentleOS) searchUrl clock24Hour;

    # Theme picker (ThemePicker.qml): the wallpapers, the active generation's
    # theme, and gentle-theme and the state file it reports through.
    # None to pick from when you've set your own (gentleOS.theme.image).
    themeWallpapers = lib.optionals (config.gentleOS.theme.image == null)
      (import ../../../../../pkgs/wallpapers { inherit pkgs; }).names;
    themeFile = "${config.xdg.configHome}/gentle-theme/current.json";
    gentleTheme = exe gentleTheme;
    themeState = "${config.xdg.stateHome}/gentle-theme.json";
  };

  shellFont = config.gentleOS.shellFont;

  shellConfig = pkgs.runCommandLocal "quickshell-gentle" { nativeBuildInputs = [ pkgs.fontconfig ]; } ''
    # A wrong name would otherwise fall back to some other font without a word.
    families=$(HOME=$TMPDIR fc-scan --format '%{family}\n' ${shellFont.package}/share | tr , '\n' | sort -u)
    if ! grep -qxF ${lib.escapeShellArg shellFont.name} <<<"$families"; then
      # Last, since Nix only shows the end of a failed build's log.
      echo "Families in ${shellFont.package.name}:" >&2
      echo "$families" >&2
      echo "gentleOS.shellFont.name: no family ${lib.escapeShellArg shellFont.name} in ${shellFont.package.name}. It has the ones above." >&2
      exit 1
    fi
    cp -r ${./shell} $out
    chmod u+w $out
    cp ${pkgs.writeText "Theme.qml.json" (builtins.toJSON theme)} $out/Theme.qml.json
    cp ${pkgs.writeText "Settings.qml.json" (builtins.toJSON settings)} $out/Settings.qml.json
    cp ${schemeCatalog} $out/ThemeSchemes.qml.json
  '';
in
{
  config = {
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

    home.packages = [ pinentry gentleTheme shellFont.package ];
    xdg.configFile."gentle-theme/current.json".text = builtins.toJSON theme;
    programs.rbw.settings.pinentry = lib.mkIf config.programs.rbw.enable pinentry;

    systemd.user.services.quickshell.Unit = {
      # Stop with the session (UWSM stops graphical-session.target on logout).
      PartOf = [ "graphical-session.target" ];
      # Restart on `home-manager switch` when the config changes: the running
      # shell keeps watching the old store path and never reloads by itself.
      X-Restart-Triggers = [ "${shellConfig}" ];
    };
  };
}

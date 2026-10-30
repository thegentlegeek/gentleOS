{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};

  exe = lib.getExe;
  hyprshot = exe pkgs.hyprshot;
  playerctl = exe pkgs.playerctl;
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = exe pkgs.brightnessctl;
  shotDir = "$HOME/Pictures/Screenshots";
  quickshell = exe config.programs.quickshell.package;
  shell = fn: "${quickshell} ipc -c gentle call shell ${fn}";

  # Commands used by binds in hyprland.lua (prepended as `local cmd = {...}`).
  # Tools binds depend on use store paths; user apps are left to PATH.
  cmd = {
    terminal = "${exe pkgs.kitty} fish";
    fileManager = "${exe pkgs.kitty} yazi";
    browserPersonal = lib.escapeShellArgs config.gentleOS.browser.personal;
    browserWork = lib.escapeShellArgs config.gentleOS.browser.work;
    editor = "codium";
    music = "${exe pkgs.kitty} spotify_player";
    calculator = "gnome-calculator";
    # Through logind so it goes via hypridle's lock_cmd (no stacked lock screens).
    lock = "loginctl lock-session";
    logout = "${exe pkgs.uwsm} stop";
    colorPicker = "${exe pkgs.hyprpicker} -a";
    shotClip = "${hyprshot} -m region --clipboard-only";
    shotEdit = "${hyprshot} -m region --raw | ${exe pkgs.swappy} -f -";
    shotSave = "${hyprshot} -m region -o ${shotDir}";
    shotScreen = "${hyprshot} -m output -m active -o ${shotDir}";
    # The shell's OSD follows Pipewire by itself; the nudge shows it at 100%
    # too, and for brightness, which it only polls (shell.qml `osd`).
    volUp = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; ${shell "osd volume"}";
    volDown = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    volMute = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
    micMute = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    playPause = "${playerctl} play-pause";
    next = "${playerctl} next";
    prev = "${playerctl} previous";
    brightUp = "${brightnessctl} s 10%+; ${shell "osd brightness"}";
    brightDown = "${brightnessctl} s 10%-; ${shell "osd brightness"}";
    # The Quickshell shell's launcher and panels (quickshell/shell/shell.qml IpcHandler).
    menu = shell "toggleLauncher";
    clipboard = shell "openLauncher clipboard";
    cheatsheet = shell "openLauncher keybinds";
    notifications = shell "toggleNotifications";
    quickSettings = shell "toggleQuickSettings";
    doNotDisturb = shell "toggleDnd";
    keepAwake = shell "toggleCaffeine";
  };

  # `gentle-screenshots`: README screenshots for every theme (./screenshots.sh).
  screenshots = pkgs.writeShellApplication {
    name = "gentle-screenshots";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep grim jq libnotify procps ];
    runtimeEnv = {
      KITTY = exe pkgs.kitty;
      QUICKSHELL = quickshell;
      # Desktop services that read the theme at startup.
      RELOAD_UNITS = lib.concatStringsSep " " (
        [ "quickshell.service" ] ++ lib.optional config.services.hyprpaper.enable "hyprpaper.service"
      );
    };
    text = builtins.readFile ./screenshots.sh;
  };
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
    extraConfig =
      "local cmd = ${lib.generators.toLua { } cmd}\n\n" + builtins.readFile ./hyprland.lua;
  };

  # Session environment, loaded by UWSM before the compositor starts and exported
  # to Hyprland, the apps it launches, and systemd user units (quickshell...).
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

  home.packages = [ screenshots ];

  # Clipboard history (text + images), as user services instead of compositor
  # autostart so they restart on crash.
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # playerctl media keys (and the bar's media pill) target the most recently
  # active MPRIS player.
  services.playerctld.enable = true;

  # Polkit agent (Hyprland's own). User service on graphical-session.target, which
  # UWSM provides; finds the session via logind, so no XDG_SESSION_ID needed.
  services.hyprpolkitagent.enable = true;
}

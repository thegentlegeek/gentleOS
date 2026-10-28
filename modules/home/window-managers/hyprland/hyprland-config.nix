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
  rofi = exe config.programs.rofi.finalPackage;
  cliphist = exe pkgs.cliphist;
  hyprshot = exe pkgs.hyprshot;
  playerctl = exe pkgs.playerctl;
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = exe pkgs.brightnessctl;
  shotDir = "$HOME/Pictures/Screenshots";

  clipboardPicker = pkgs.writeShellScript "clipboard-picker" ''
    ${cliphist} list \
      | ${rofi} -dmenu -i -p Clipboard -display-columns 2 \
      | ${cliphist} decode \
      | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  # Cheat sheet generated from the live binds' descriptions ("Category: text").
  # hyprctl comes from PATH so it always matches the running compositor.
  cheatsheet = pkgs.writeShellScript "hypr-cheatsheet" ''
    hyprctl binds -j | ${exe pkgs.jq} -r '
      def bit(n): ((.modmask / n) | floor) % 2 == 1;
      def mods: [ (if bit(64) then "SUPER" else empty end),
                  (if bit(4)  then "CTRL"  else empty end),
                  (if bit(8)  then "ALT"   else empty end),
                  (if bit(1)  then "SHIFT" else empty end) ];
      def pretty: {"mouse:272": "Left drag", "mouse:273": "Right drag",
                   "mouse_up": "Scroll up", "mouse_down": "Scroll down",
                   "slash": "/", "Escape": "Esc", "Return": "Enter",
                   "left": "Left", "right": "Right", "up": "Up", "down": "Down"}[.] // .
                  | sub("^XF86"; "");
      .[] | select(.has_description)
      | (.description | capture("^(?<cat>[^:]+):\\s*(?<text>.*)$")
           // {cat: "Other", text: .}) as $d
      | [ $d.cat,
          ((mods + [(.key | pretty)]) | join(" + "))
            + (if .submap != "" then " [" + .submap + " mode]" else "" end),
          $d.text ]
      | @tsv' \
      | ${pkgs.coreutils}/bin/sort -s -t "$(printf '\t')" -k1,1 \
      | ${exe pkgs.gawk} -F '\t' '{ printf "%-12s %-32s %s\n", $1, $2, $3 }' \
      | ${rofi} -dmenu -i -p Keybinds -no-custom \
          -theme-str 'window { width: 60%; } * { font: "JetBrainsMono Nerd Font Mono 11"; }' \
      > /dev/null
  '';

  # Commands used by binds in hyprland.lua (prepended as `local cmd = {...}`).
  # Tools binds depend on use store paths; user apps are left to PATH.
  cmd = {
    terminal = "${exe pkgs.kitty} fish";
    fileManager = "${exe pkgs.kitty} yazi";
    menu = "${rofi} -show drun -display-drun ''";
    browserPersonal = ''chromium --profile-directory="Profile 2"'';
    browserWork = ''chromium --profile-directory="Profile 3"'';
    editor = "codium";
    music = "${exe pkgs.kitty} spotify_player";
    calculator = "gnome-calculator";
    # Through logind so it goes via hypridle's lock_cmd (no stacked lock screens).
    lock = "loginctl lock-session";
    logout = "${exe pkgs.uwsm} stop";
    cheatsheet = "${cheatsheet}";
    clipboard = "${clipboardPicker}";
    colorPicker = "${exe pkgs.hyprpicker} -a";
    shotClip = "${hyprshot} -m region --clipboard-only";
    shotEdit = "${hyprshot} -m region --raw | ${exe pkgs.swappy} -f -";
    shotSave = "${hyprshot} -m region -o ${shotDir}";
    shotScreen = "${hyprshot} -m output -m active -o ${shotDir}";
    volUp = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
    volDown = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    volMute = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
    micMute = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    playPause = "${playerctl} play-pause";
    next = "${playerctl} next";
    prev = "${playerctl} previous";
    brightUp = "${brightnessctl} s 10%+";
    brightDown = "${brightnessctl} s 10%-";
  } // lib.optionalAttrs (config.gentleOS.desktopShell == "quickshell") (
    # Panels of the Quickshell shell (quickshell/shell/shell.qml IpcHandler).
    let shell = fn: "${exe config.programs.quickshell.package} ipc -c gentle call shell ${fn}"; in {
      notifications = shell "toggleNotifications";
      quickSettings = shell "toggleQuickSettings";
      doNotDisturb = shell "toggleDnd";
      keepAwake = shell "toggleCaffeine";
    }
  );
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

  # playerctl media keys (and Waybar's mpris module, which defaults to the
  # playerctld proxy) target the most recently active MPRIS player.
  services.playerctld.enable = true;

  # Polkit agent (Hyprland's own). User service on graphical-session.target, which
  # UWSM provides; finds the session via logind, so no XDG_SESSION_ID needed.
  services.hyprpolkitagent.enable = true;
}

{
  config,
  lib,
  pkgs,
  ...
}:

let
  rofi = lib.getExe config.programs.rofi.finalPackage;
  # Picking an entry is the confirmation; Esc cancels.
  powerMenu = pkgs.writeShellScript "power-menu" ''
    choice=$(printf '%s\n' "Lock" "Log out" "Suspend" "Reboot" "Shut down" \
      | ${rofi} -dmenu -i -p Power -no-custom)
    case "$choice" in
      "Lock")      loginctl lock-session ;;
      "Log out")   ${lib.getExe pkgs.uwsm} stop ;;
      # Same action as closing the lid / hypridle's long timeout.
      "Suspend")   systemctl suspend-then-hibernate ;;
      "Reboot")    systemctl reboot ;;
      "Shut down") systemctl poweroff ;;
    esac
  '';
in
{
  imports =
    [
      ./style.nix
    ];

config = lib.mkIf (config.gentleOS.desktopShell == "waybar") {
programs.waybar = {
    enable = true;
    # Run from HM (graphical-session.target) rather than the NixOS module, so
    # config and service live in one place.
    systemd.enable = true;
    settings = {
    mainBar = {
        layer = "top"; # Waybar at top layer
        position = "top"; # Waybar position (top|bottom|left|right)
        spacing = 4; # Gaps between modules (4px)
        # Choose the order of the modules
        modules-left = [
            "hyprland/workspaces"
        ];
        modules-center = [
            "clock"
            "mpris"
        ];
        modules-right = [
            "wireplumber"
            "network"
            "cpu"
            "temperature"
            "backlight"
            "keyboard-state"
            "battery"
            "power-profiles-daemon"
            "tray" # applets (blueman etc.)
            "idle_inhibitor" # click to pause/resume auto-lock (hypridle)
            "custom/power"
        ];
        "hyprland/workspaces" =  {
            format = "{name} {icon}";
            on-click = "activate";
            format-icons = {
                urgent = "";
                active = "";
                default = "";
            };
            sort-by-number = true;
        };
        # No `player`: follows the playerctld proxy (services.playerctld below),
        # i.e. the most recently active MPRIS player, like the media keys.
        mpris = {
            format = "{player_icon} {title} {position}/{length}";
            format-paused = "{status_icon} <i>{title} {position}/{length}</i>";
            player-icons = {
                default = "▶";
            };
            status-icons = {
                paused = "⏸";
            };
            tooltip-format = ''
                Artist: {artist}
                Album: {album}
                Title: {title}'';
        };
        keyboard-state = {
            numlock = false;
            capslock = true;
            format = "{icon} {name}";
            format-icons = {
                locked = "";
                unlocked = "";
            };
        };
        idle_inhibitor = {
            format = "{icon}";
            format-icons = {
                activated = "";
                deactivated = "";
            };
        };
        tray = {
            spacing = 10;
        };
        clock = {
            format = "{:%A, %b %e • %I:%M}";
            # Must stay explicit: without it Waybar's clock auto-detects the zone
            # via libstdc++'s tzdb, which falls back to UTC on NixOS. Keep in sync
            # with time.timeZone (modules/nixos/workstation).
            timezone = "America/Indiana/Indianapolis";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%H:%M}";
        };
        cpu = {
            format = " {usage}%";
            tooltip = false;
        };
        temperature = {
            # k10temp (Tctl) via its PCI function address, which is stable
            # across boots — thermal-zone/hwmonN indices are not.
            "hwmon-path-abs" = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
            "input-filename" = "temp1_input";
            critical-threshold = 90;
            # "format-critical = "{temperatureF}°F {icon}";
            format = "{icon} {temperatureC}°C";
            format-icons = ["" "" ""];
        };
        backlight = {
            # "device = "acpi_video1";
            format = "{icon} {percent}%";
            format-icons = ["" "" "" "" "" "" "" "" ""];
        };
        battery = {
            states = {
                # good = 95,
                warning = 30;
                critical = 15;
            };
            format = "{icon} {capacity}%";
            format-full = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = " {capacity}%";
            format-alt = "{icon} {time}";
            # format-good = ""; # An empty format will hide the module
            # format-full = "";
            format-icons = ["" "" "" "" ""];
        };
        power-profiles-daemon = {
            format = "{icon}";
            tooltip-format = "Power profile: {profile}\nDriver: {driver}";
            tooltip = true;
            format-icons = {
                default = "";
                performance = "";
                balanced = "";
                power-saver = "";
            };
        };
        network = {
            format-wifi = " {essid}";
            format-ethernet = " {ipaddr}";
            tooltip-format = " {ifname} via {gwaddr}";
            tooltip-format-wifi = "{signalStrength}%/{signaldBm}dBm\n{frequency}GHz\nDown: {bandwidthDownBits}";
            format-linked = "{ifname} (No IP) 󰌙";
            format-disconnected = "⚠ Disconnected";
            format-alt = "{bandwidthTotalBytes}";
        };
        wireplumber = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%";
            format-bluetooth-muted = "󰝟 {icon}";
            format-muted = "󰝟";
            format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                portable = "";
                car = "";
                default = ["" "" ""];
            };
            on-click = "pavucontrol";
            scroll-step = 5;
        };
        "custom/power" = {
            format = "⏻ ";
            tooltip-format = "Power menu";
            on-click = "${powerMenu}";
        };
        };
      };
   };
};
}

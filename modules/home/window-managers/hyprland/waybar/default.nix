{
  ...
}:

{
  imports =
    [
      ./style.nix
    ];

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
        mpris = {
            player = "spotify_player";
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
            # "icon-size = 21;
            spacing = 10;
        };
        clock = {
            format = "{:%A, %b %e • %I:%M}";
            timezone = "America/Indiana/Indianapolis";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%H:%M}";
        };
        cpu = {
            format = " {usage}%";
            tooltip = false;
        };
        memory = {
            format = "{}% ";
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
        "custom/media" = {
            format = "{icon} {text}";
            return-type = "json";
            max-length = 40;
            format-icons = {
                spotify = "";
                default = "🎜";
            };
            escape = true;
            exec = "spotify 2> /dev/null"; # Script in resources folder
            # "exec = "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" # Filter player based on name
        };
        "custom/power" = {
            format = "⏻ ";
            tooltip = false;
            on-click = "shutdown now";
        };
        };
      };
   };
}

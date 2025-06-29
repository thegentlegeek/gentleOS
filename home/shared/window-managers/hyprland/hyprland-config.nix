{
  ...
}:
  let
      terminal = "kitty fish";
      fileManager = "thunar";
      menu = "rofi -show drun -display-drun ''";
      pbrowser = "chromium %U --profile-directory=\"Profile 2\"";
      wbrowser = "chromium %U --profile-directory=\"Profile 3\"";
      scrnshotCopy = "grimblast copy area";
      scrnshotSave = "grimblast save area - | swappy -f -";
      editor = "codium";
      music = "kitty spotify_player";
      laptopDisplayOff = "eDP-1, disable";
      laptopDisplayOn = "eDP-1, 1920x1200, 0x0, 1";
      calculator = "gnome-calculator";
      lock = "hyprlock";
  in
{
  qt = {
    enable = true;
    style.name = "breeze";
    platformTheme.name = "adwaita";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      "$mainmod" = "SUPER";

      # Monitor configuration
      monitor = [
        "HDMI-A-1,3840x2160@60,0x0,1"
        ", preferred, auto, 1"
      ];

      # Autostart applications
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dunst"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        #''
        #spotify_player -d & while [ "$(spotify_player get key playback)" = "null" ]; do sleep 1; done; spotify_player playback volume 50; spotify_player playback play
        #''
      ];

      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "MOZ_ENABLE_WAYLAND,1"
        "GDK_SCALE,1"
      ];

      # General configuration
      general = {
        gaps_in = 3;
        gaps_out = 8;
        border_size = 2;
        # col.active_border = 
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decorations
      decoration = {
        rounding = 10;
        active_opacity = 0.93;
        inactive_opacity = 0.8;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          popups = false;
          vibrancy = 0.1696;
          ignore_opacity = true;
          xray = false;
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };

      # Workspace swiping
      gestures = {
        workspace_swipe = true;
      };

      # Basic keybindings
      bind = [
        "$mainmod, L, exec, ${lock}"
        "$mainmod, C, exec, ${terminal}"
        "$mainmod, Q, killactive"
        "$mainmod, M, exec, ${music}"
        "$mainmod, F, exec, ${fileManager}"
        "$mainmod, V, togglefloating"
        "$mainmod, A, exec, ${menu}"
        "$mainmod SHIFT, C, exec, ${calculator}"

        # Window management keybindings
        "$mainmod, P, pseudo"
        "$mainmod, J, togglesplit"
        "$mainmod, T, exec, ${scrnshotCopy}"
        "$mainmod SHIFT, T, exec, ${scrnshotSave}"
        "$mainmod, left, movefocus, l"
        "$mainmod, right, movefocus, r"
        "$mainmod, up, movefocus, u"
        "$mainmod, down, movefocus, d"

        # Browser and editor keybindings
        "$mainmod SHIFT, B, exec, ${wbrowser}"
        "$mainmod, B, exec, ${pbrowser}"
        "$mainmod, E, exec, ${editor}"

        # Workspace switching keybindings
        "$mainmod, 1, workspace, 1"
        "$mainmod, 2, workspace, 2"
        "$mainmod, 3, workspace, 3"
        "$mainmod, 4, workspace, 4"
        "$mainmod, 5, workspace, 5"
        "$mainmod, 6, workspace, 6"
        "$mainmod, 7, workspace, 7"
        "$mainmod, 8, workspace, 8"
        "$mainmod, 9, workspace, 9"
        "$mainmod, 0, workspace, 10"

        # Moving windows between workspaces keybindings
        "$mainmod SHIFT, 1, movetoworkspace, 1"
        "$mainmod SHIFT, 2, movetoworkspace, 2"
        "$mainmod SHIFT, 3, movetoworkspace, 3"
        "$mainmod SHIFT, 4, movetoworkspace, 4"
        "$mainmod SHIFT, 5, movetoworkspace, 5"
        "$mainmod SHIFT, 6, movetoworkspace, 6"
        "$mainmod SHIFT, 7, movetoworkspace, 7"
        "$mainmod SHIFT, 8, movetoworkspace, 8"
        "$mainmod SHIFT, 9, movetoworkspace, 9"
        "$mainmod SHIFT, 0, movetoworkspace, 10"

        # Special workspaces keybindings
        "$mainmod, S, togglespecialworkspace, magic"
        "$mainmod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces
        "$mainmod, mouse_up, workspace, e+1"
        "$mainmod, mouse_down, workspace, e-1"
        "$mainmod CTRL, right, workspace, e+1"
        "$mainmod CTRL, left, workspace, e-1"
      ];

      # Mouse bindings
      bindm = [
        "$mainmod, mouse:272, movewindow"
        "$mainmod, mouse:273, resizewindow"
      ];

      bindel = [
        # Multimedia and brightness keys
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];


      # Monitor Management
      bindl = [
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor ${laptopDisplayOff}"
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor ${laptopDisplayOn}"
      ];

      # Window rules
      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "float, class:^(xdg-desktop-portal-gtk)$, title:^(Open Files)$"
        "float, class:^(xdg-desktop-portal-gtk)$, title:^(All Files)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, class:^(org.pulseaudio.pavucontrol)$"
        "float, initialTitle:^(_crx_mpdajninpobndbfcldcmbpnnbhibjmch)$"
        "float, title:^(OpenSSH Authentication Passphrase request)$"

        # Windows to not have transparency
        "opacity 1.0 override 1.0 override, title:^(Hulu | Watch — Mozilla Firefox)"
        "opacity 1.0 override 1.0 override, class:^(vlc)$, initialTitle:^(VLC media player)"
        "opacity 1.0 override 1.0 override, class:^(org.inkscape.Inkscape)$"
        "opacity 1.0 override 1.0 override, class:^(FreeTube)$"
        
        # Force focus
        "stayfocused, initialTitle:^(Commit Changes — Kate)$"
        "stayfocused, initialTitle:^(Create New File — Dolphin)$"
      ];
    };
  };
}

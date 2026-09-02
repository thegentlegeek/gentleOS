{
  lib,
  ...
}:
  let
      inherit (lib.generators) mkLuaInline;

      # Hyprland Lua DSL helpers
      luaq = lib.escape [ "\"" ];
      exec = cmd: mkLuaInline "hl.dsp.exec_cmd(\"${luaq cmd}\")";
      key = k: mkLuaInline "mod .. \" + ${k}\"";
      bind = k: action: { _args = [ (key k) action ]; };
      bindW = k: action: opts: { _args = [ (key k) action opts ]; };

      terminal = "kitty fish";
      fileManager = "kitty yazi";
      menu = "rofi -show drun -display-drun ''";
      pbrowser = ''chromium %U --profile-directory="Profile 2"'';
      wbrowser = ''chromium %U --profile-directory="Profile 3"'';
      scrnshotCopy = "hyprshot -m region --clipboard-only";
      scrnshotSave = "hyprshot -m region -- swappy";
      editor = "codium";
      music = "kitty spotify_player";
      calculator = "gnome-calculator";
      lock = "hyprlock";
      laptopDisplayOff = "hyprctl keyword monitor eDP-1, disable";
      laptopDisplayOn = "hyprctl keyword monitor eDP-1, 1920x1200, 0x0, 1";
  in
{
  qt = {
    enable = true;
    style.name = "breeze";
    platformTheme.name = "adwaita";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = true;
    settings = {
      # Rendered as a Lua local: `local mod = "SUPER"`
      mod = { _var = "SUPER"; };

      # Monitor configuration
      monitor = [
        { output = "HDMI-A-1"; mode = "3840x2160@60"; position = "0x0"; scale = 1; }
        { output = ""; mode = "preferred"; position = "auto"; scale = "auto"; }
      ];

      # Autostart applications (replaces hyprlang exec-once)
      on = {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd("dunst")
              hl.exec_cmd("wl-paste --type text --watch cliphist store")
              hl.exec_cmd("wl-paste --type image --watch cliphist store")
            end
          '')
        ];
      };

      # Environment variables
      env = [
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; }
        { _args = [ "QT_QPA_PLATFORMTHEME" "qt6ct" ]; }
        { _args = [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]; }
        { _args = [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]; }
        { _args = [ "MOZ_ENABLE_WAYLAND" "1" ]; }
        { _args = [ "GDK_SCALE" "1" ]; }
      ];

      # Configuration sections (general, decoration, input)
      config = {
        general = {
          gaps_in = 3;
          gaps_out = 8;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

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

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = true;
          };
        };
      };

      # Animations
      curve = {
        _args = [
          "myBezier"
          {
            type = "bezier";
            points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ];
          }
        ];
      };

      animation = [
        { leaf = "windows"; enabled = true; speed = 7; bezier = "myBezier"; }
        { leaf = "windowsOut"; enabled = true; speed = 7; bezier = "default"; style = "popin 80%"; }
        { leaf = "border"; enabled = true; speed = 10; bezier = "default"; }
        { leaf = "borderangle"; enabled = true; speed = 8; bezier = "default"; }
        { leaf = "fade"; enabled = true; speed = 7; bezier = "default"; }
        { leaf = "workspaces"; enabled = true; speed = 6; bezier = "default"; }
      ];

      # Swipe gestures
      gesture = [
        { fingers = 3; direction = "horizontal"; action = "workspace"; }
        { fingers = 4; direction = "up"; action = "fullscreen"; }
      ];

      # Keybindings
      bind = [
        (bind "L" (exec lock))
        (bind "C" (exec terminal))
        { _args = [ (key "Q") (mkLuaInline "hl.dsp.window.close()") ]; }
        (bind "M" (exec music))
        (bind "F" (exec fileManager))
        { _args = [ (key "V") (mkLuaInline "hl.dsp.window.float({ action = \"toggle\" })") ]; }
        (bind "A" (exec menu))
        (bind "SHIFT + C" (exec calculator))

        # Window management keybindings
        { _args = [ (key "P") (mkLuaInline "hl.dsp.window.pseudo()") ]; }
        { _args = [ (key "J") (mkLuaInline "hl.dsp.layout(\"togglesplit\")") ]; }
        (bind "T" (exec scrnshotCopy))
        (bind "SHIFT + T" (exec scrnshotSave))
        { _args = [ (key "left") (mkLuaInline "hl.dsp.focus({ direction = \"left\" })") ]; }
        { _args = [ (key "right") (mkLuaInline "hl.dsp.focus({ direction = \"right\" })") ]; }
        { _args = [ (key "up") (mkLuaInline "hl.dsp.focus({ direction = \"up\" })") ]; }
        { _args = [ (key "down") (mkLuaInline "hl.dsp.focus({ direction = \"down\" })") ]; }

        # Browser and editor keybindings
        (bind "SHIFT + B" (exec wbrowser))
        (bind "B" (exec pbrowser))
        (bind "E" (exec editor))

        # Workspace switching keybindings
        { _args = [ (key "1") (mkLuaInline "hl.dsp.focus({ workspace = 1 })") ]; }
        { _args = [ (key "2") (mkLuaInline "hl.dsp.focus({ workspace = 2 })") ]; }
        { _args = [ (key "3") (mkLuaInline "hl.dsp.focus({ workspace = 3 })") ]; }
        { _args = [ (key "4") (mkLuaInline "hl.dsp.focus({ workspace = 4 })") ]; }
        { _args = [ (key "5") (mkLuaInline "hl.dsp.focus({ workspace = 5 })") ]; }
        { _args = [ (key "6") (mkLuaInline "hl.dsp.focus({ workspace = 6 })") ]; }
        { _args = [ (key "7") (mkLuaInline "hl.dsp.focus({ workspace = 7 })") ]; }
        { _args = [ (key "8") (mkLuaInline "hl.dsp.focus({ workspace = 8 })") ]; }
        { _args = [ (key "9") (mkLuaInline "hl.dsp.focus({ workspace = 9 })") ]; }
        { _args = [ (key "0") (mkLuaInline "hl.dsp.focus({ workspace = 10 })") ]; }

        # Moving windows between workspaces keybindings
        { _args = [ (key "SHIFT + 1") (mkLuaInline "hl.dsp.window.move({ workspace = 1 })") ]; }
        { _args = [ (key "SHIFT + 2") (mkLuaInline "hl.dsp.window.move({ workspace = 2 })") ]; }
        { _args = [ (key "SHIFT + 3") (mkLuaInline "hl.dsp.window.move({ workspace = 3 })") ]; }
        { _args = [ (key "SHIFT + 4") (mkLuaInline "hl.dsp.window.move({ workspace = 4 })") ]; }
        { _args = [ (key "SHIFT + 5") (mkLuaInline "hl.dsp.window.move({ workspace = 5 })") ]; }
        { _args = [ (key "SHIFT + 6") (mkLuaInline "hl.dsp.window.move({ workspace = 6 })") ]; }
        { _args = [ (key "SHIFT + 7") (mkLuaInline "hl.dsp.window.move({ workspace = 7 })") ]; }
        { _args = [ (key "SHIFT + 8") (mkLuaInline "hl.dsp.window.move({ workspace = 8 })") ]; }
        { _args = [ (key "SHIFT + 9") (mkLuaInline "hl.dsp.window.move({ workspace = 9 })") ]; }
        { _args = [ (key "SHIFT + 0") (mkLuaInline "hl.dsp.window.move({ workspace = 10 })") ]; }

        # Special workspaces keybindings
        { _args = [ (key "S") (mkLuaInline "hl.dsp.workspace.toggle_special(\"magic\")") ]; }
        { _args = [ (key "SHIFT + S") (mkLuaInline "hl.dsp.window.move({ workspace = \"special:magic\" })") ]; }

        # Scroll through existing workspaces
        { _args = [ (key "mouse_up") (mkLuaInline "hl.dsp.focus({ workspace = \"e+1\" })") ]; }
        { _args = [ (key "mouse_down") (mkLuaInline "hl.dsp.focus({ workspace = \"e-1\" })") ]; }
        { _args = [ (key "CTRL + right") (mkLuaInline "hl.dsp.focus({ workspace = \"e+1\" })") ]; }
        { _args = [ (key "CTRL + left") (mkLuaInline "hl.dsp.focus({ workspace = \"e-1\" })") ]; }

        # Mouse bindings
        { _args = [ (key "mouse:272") (mkLuaInline "hl.dsp.window.drag()") { mouse = true; } ]; }
        { _args = [ (key "mouse:273") (mkLuaInline "hl.dsp.window.resize()") { mouse = true; } ]; }

        # Multimedia and brightness keys (repeat while held, work when locked)
        { _args = [ "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { locked = true; repeating = true; } ]; }
        { _args = [ "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { locked = true; repeating = true; } ]; }
        { _args = [ "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { locked = true; repeating = true; } ]; }
        { _args = [ "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { locked = true; repeating = true; } ]; }
        { _args = [ "XF86MonBrightnessUp" (exec "brightnessctl s 10%+") { locked = true; repeating = true; } ]; }
        { _args = [ "XF86MonBrightnessDown" (exec "brightnessctl s 10%-") { locked = true; repeating = true; } ]; }

        # Monitor management (lid switch, work when locked)
        { _args = [ "switch:on:Lid Switch" (exec laptopDisplayOff) { locked = true; } ]; }
        { _args = [ "switch:off:Lid Switch" (exec laptopDisplayOn) { locked = true; } ]; }
      ];

      # Window rules (0.53+ rule engine)
      window_rule = [
        { match.class = ".*"; suppress_event = "maximize"; }
        { match = { class = "^(xdg-desktop-portal-gtk)$"; title = "^(Open Files)$"; }; float = true; }
        { match = { class = "^(xdg-desktop-portal-gtk)$"; title = "^(All Files)$"; }; float = true; }
        { match.class = "^(org.gnome.Calculator)$"; float = true; }
        { match.class = "^(org.pulseaudio.pavucontrol)$"; float = true; }
        { match.initial_title = "^(_crx_mpdajninpobndbfcldcmbpnnbhibjmch)$"; float = true; }
        { match.title = "^(OpenSSH Authentication Passphrase request)$"; float = true; }

        # Windows to not have transparency
        { match.title = "^(Hulu | Watch — Mozilla Firefox)$"; opacity = "1.0 override 1.0 override"; }
        { match = { class = "^(vlc)$"; initial_title = "^(VLC media player)$"; }; opacity = "1.0 override 1.0 override"; }
        { match.class = "^(org.inkscape.Inkscape)$"; opacity = "1.0 override 1.0 override"; }
        { match.class = "^(FreeTube)$"; opacity = "1.0 override 1.0 override"; }

        # Force focus
        { match.initial_title = "^(Commit Changes — Kate)$"; stay_focused = true; }
        { match.initial_title = "^(Create New File — Dolphin)$"; stay_focused = true; }
      ];
    };
  };
}

-- Hyprland config (Lua). Loaded by Home Manager via extraConfig in hyprland-config.nix.
-- Must stay valid on both the running Hyprland and the next upstream release we
-- pin; validate with `Hyprland --verify-config -c <generated hyprland.lua>`.
-- API reference: example/hyprland.lua in the Hyprland source tree.

------------------
---- PROGRAMS ----
------------------

local terminal     = "kitty fish"
local fileManager  = "kitty yazi"
local menu         = "rofi -show drun -display-drun ''"
local pbrowser     = [[chromium %U --profile-directory="Profile 2"]]
local wbrowser     = [[chromium %U --profile-directory="Profile 3"]]
local scrnshotCopy = "hyprshot -m region --clipboard-only"
local scrnshotSave = "hyprshot -m region -- swappy"
local editor       = "codium"
local music        = "kitty spotify_player"
local calculator   = "gnome-calculator"
local lock         = "hyprlock"


------------------
---- MONITORS ----
------------------

-- Explicit scales: the default "auto" picks 1.5x on the laptop panel.
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "0x0",              scale = 1 })
-- Laptop panel sits below the external monitor, centered: x = (3840 - 1920) / 2,
-- y = 2160. Fixed rather than "auto-center-down", which kept a negative offset
-- (-960,0) after HDMI was unplugged; a positive offset alone is harmless.
hl.monitor({ output = "eDP-1",    mode = "preferred",    position = "960x2160",         scale = 1 })
hl.monitor({ output = "",         mode = "preferred",    position = "auto",             scale = 1 })


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dunst")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_SCALE", "1")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Border/group colors and misc.background_color come from Stylix (hl.config above this file).
hl.config({
    general = {
        gaps_in          = 3,
        gaps_out         = 8,
        border_size      = 2,
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    -- amdgpu (Phoenix, DCN 3.1.4): region damage tracking reuses stale
    -- buffer content, causing Waybar flicker on pointer motion (blocky
    -- trails if hardware cursors are disabled instead). Confirmed
    -- independent of blur. Force whole-monitor damage as a workaround.
    -- Revisit after the kernel bump in hosts/zbook/default.nix.
    debug = {
        damage_tracking = 1,
    },

    decoration = {
        rounding         = 10,
        active_opacity   = 0.93,
        inactive_opacity = 0.8,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            popups            = false,
            vibrancy          = 0.1696,
            ignore_opacity    = true,
            xray              = false,
        },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })


------------------
---- GESTURES ----
------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up",         action = "fullscreen" })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local function key(k) return mainMod .. " + " .. k end

hl.bind(key("L"),         hl.dsp.exec_cmd(lock))
hl.bind(key("C"),         hl.dsp.exec_cmd(terminal))
hl.bind(key("Q"),         hl.dsp.window.close())
hl.bind(key("M"),         hl.dsp.exec_cmd(music))
hl.bind(key("F"),         hl.dsp.exec_cmd(fileManager))
hl.bind(key("V"),         hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("A"),         hl.dsp.exec_cmd(menu))
hl.bind(key("SHIFT + C"), hl.dsp.exec_cmd(calculator))

-- Window management
hl.bind(key("P"),         hl.dsp.window.pseudo())
hl.bind(key("J"),         hl.dsp.layout("togglesplit"))
hl.bind(key("T"),         hl.dsp.exec_cmd(scrnshotCopy))
hl.bind(key("SHIFT + T"), hl.dsp.exec_cmd(scrnshotSave))
hl.bind(key("left"),      hl.dsp.focus({ direction = "left" }))
hl.bind(key("right"),     hl.dsp.focus({ direction = "right" }))
hl.bind(key("up"),        hl.dsp.focus({ direction = "up" }))
hl.bind(key("down"),      hl.dsp.focus({ direction = "down" }))

-- Browser and editor
hl.bind(key("SHIFT + B"), hl.dsp.exec_cmd(wbrowser))
hl.bind(key("B"),         hl.dsp.exec_cmd(pbrowser))
hl.bind(key("E"),         hl.dsp.exec_cmd(editor))

-- Workspaces 1-10 (key 0 is workspace 10)
for i = 1, 10 do
    local k = tostring(i % 10)
    hl.bind(key(k),              hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(key("S"),         hl.dsp.workspace.toggle_special("magic"))
hl.bind(key("SHIFT + S"), hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces
hl.bind(key("mouse_up"),     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_down"),   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(key("CTRL + right"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("CTRL + left"),  hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mainMod + LMB/RMB. 0.55 infers mouse binds from the key;
-- 0.57+ requires the explicit flag.
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Multimedia and brightness keys (repeat while held, work when locked)
local held = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  held)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  held)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), held)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), held)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), held)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), held)

-- Lid switch. `hyprctl keyword` doesn't work with Lua configs, so update the
-- monitor rule directly. hl.monitor merges into the existing eDP-1 rule (mode,
-- position and scale come from MONITORS above), so re-enabling only has to
-- clear `disabled`.
--
-- hl.monitor changes are only applied on the next rendered frame. If eDP-1 is
-- the only active output, disabling it stops all rendering and the re-enable
-- on lid open never applies (black screen). So only disable it when another
-- output is active; undocked, logind suspends on lid close anyway.
local function otherOutputActive()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= "eDP-1" and m.name ~= "FALLBACK" then
            return true
        end
    end
    return false
end

hl.bind("switch:on:Lid Switch", function()
    if otherOutputActive() then
        hl.monitor({ output = "eDP-1", disabled = true })
    end
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false })
end, { locked = true })


----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- Floating dialogs and small utilities
hl.window_rule({ name = "float-portal-open-files", match = { class = "^(xdg-desktop-portal-gtk)$", title = "^(Open Files)$" }, float = true })
hl.window_rule({ name = "float-portal-all-files",  match = { class = "^(xdg-desktop-portal-gtk)$", title = "^(All Files)$" },  float = true })
hl.window_rule({ name = "float-calculator",        match = { class = "^(org.gnome.Calculator)$" },          float = true })
hl.window_rule({ name = "float-pavucontrol",       match = { class = "^(org.pulseaudio.pavucontrol)$" },    float = true })
hl.window_rule({ name = "float-saml-tracer",       match = { initial_title = "^(_crx_mpdajninpobndbfcldcmbpnnbhibjmch)$" }, float = true })
hl.window_rule({ name = "float-ssh-askpass",       match = { title = "^(OpenSSH Authentication Passphrase request)$" },     float = true })

-- Windows that should not be transparent
local opaque = "1.0 override 1.0 override"
hl.window_rule({ name = "opaque-hulu",     match = { title = "^(Hulu | Watch — Mozilla Firefox)$" }, opacity = opaque })
hl.window_rule({ name = "opaque-vlc",      match = { class = "^(vlc)$", initial_title = "^(VLC media player)$" }, opacity = opaque })
hl.window_rule({ name = "opaque-inkscape", match = { class = "^(org.inkscape.Inkscape)$" }, opacity = opaque })
hl.window_rule({ name = "opaque-freetube", match = { class = "^(FreeTube)$" }, opacity = opaque })

-- Force focus
hl.window_rule({ name = "focus-kate-commit",    match = { initial_title = "^(Commit Changes — Kate)$" },    stay_focused = true })
hl.window_rule({ name = "focus-dolphin-newfile", match = { initial_title = "^(Create New File — Dolphin)$" }, stay_focused = true })

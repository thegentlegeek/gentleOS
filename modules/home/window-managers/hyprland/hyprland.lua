-- Hyprland config (Lua). Loaded by Home Manager via extraConfig in hyprland-config.nix.
-- Must stay valid on both the running Hyprland and the next upstream release we
-- pin; validate with `Hyprland --verify-config -c <generated hyprland.lua>`.
-- API reference: example/hyprland.lua in the Hyprland source tree.

------------------
---- PROGRAMS ----
------------------

-- `cmd` (commands used by binds, with absolute store paths for the tools they
-- rely on) is generated in hyprland-config.nix and prepended to this file.


------------------
---- MONITORS ----
------------------

-- Per-host layouts, picked by hostname at config load. GENTLEOS_HOST overrides
-- it (the flake check sets it, since the build sandbox has no /etc/hostname).
local function hostname()
    local h = os.getenv("GENTLEOS_HOST")
    if h and h ~= "" then return h end
    local f = io.open("/etc/hostname", "r")
    if not f then return "" end
    h = f:read("l") or ""
    f:close()
    return h
end

local monitorLayouts = {
    zbook = function()
        hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "0x0",      scale = 1 })
        -- Laptop panel sits below the external monitor, centered: x = (3840 - 1920) / 2,
        -- y = 2160. Fixed rather than "auto-center-down", which kept a negative offset
        -- (-960,0) after HDMI was unplugged; a positive offset alone is harmless.
        hl.monitor({ output = "eDP-1",    mode = "preferred",    position = "960x2160", scale = 1 })
    end,
}

local layout = monitorLayouts[hostname()]
if layout then layout() end

-- Fallback for anything not listed above. Explicit scale: the default "auto"
-- picks 1.5x on zbook's laptop panel.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })


-------------------
---- AUTOSTART ----
-------------------

-- Nothing is started from here: session daemons run as systemd user units under
-- UWSM so they're restarted on crash and log to the journal. The desktop shell
-- is programs.quickshell.systemd (quickshell/); cliphist is services.cliphist.


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Set in ~/.config/uwsm/env{,-hyprland} (hyprland-config.nix) instead of hl.env:
-- UWSM exports those to systemd user units too, and sets XDG_CURRENT_DESKTOP,
-- XDG_SESSION_TYPE and XDG_SESSION_DESKTOP itself.


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

    decoration = {
        rounding         = 10,
        active_opacity   = 0.95,
        inactive_opacity = 0.8,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
        },
        blur = {
            enabled           = true,
            size              = 12,
            passes            = 2,
            new_optimizations = true,
            popups            = false,
            vibrancy          = 0.1696,
            ignore_opacity    = true,
            xray              = false,
            variant           = "kawase",
        },
    },

    animations = {
        enabled = true,
    },

    -- Releases are pinned in flake.nix; skip the "what's new" popup on each bump.
    ecosystem = {
        no_update_news = true,
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

-- Bind registry for the launcher's keybinds mode (quickshell/shell/LauncherBinds.qml).
-- `hyprctl binds` can't say what a Lua bind runs, so bind() records every
-- described bind here, with its command when it's an exec_cmd (matched against
-- apps for the key hints); the list is written to $XDG_RUNTIME_DIR at the end of
-- this section. gentleBinds[desc] keeps the dispatcher, so the launcher runs a
-- bind with `dispatch gentleBinds["<desc>"]`.
local execOf = setmetatable({}, { __mode = "k" })
do
    local exec_cmd = hl.dsp.exec_cmd
    hl.dsp.exec_cmd = function(command, ...)
        local d = exec_cmd(command, ...)
        execOf[d] = command
        return d
    end
end
gentleBinds = {}
local registry = {}
local currentSubmap = ""

-- Every user-facing bind gets a "Category: text" description; the cheat sheet
-- (SUPER + /) is generated from them, so it can't drift. opts.list_only: shown
-- in the cheat sheet but not runnable from it. Mouse and submap binds never are.
local function bind(keys, dispatcher, desc, opts)
    local o = {}
    for k, v in pairs(opts or {}) do o[k] = v end
    local listOnly = o.list_only
    o.list_only = nil
    o.desc = desc
    if desc then
        registry[#registry + 1] = {
            desc = desc, keys = keys, exec = execOf[dispatcher],
            run = not (listOnly or o.mouse or currentSubmap ~= ""),
        }
        gentleBinds[desc] = gentleBinds[desc] or dispatcher
    end
    return hl.bind(keys, dispatcher, o)
end

local function submap(name, fn)
    hl.define_submap(name, function()
        currentSubmap = name
        fn()
        currentSubmap = ""
    end)
end

-- Apps
bind(key("C"),         hl.dsp.exec_cmd(cmd.terminal),        "Apps: Terminal")
bind(key("space"),     hl.dsp.exec_cmd(cmd.menu),            "Apps: App launcher")
bind(key("F"),         hl.dsp.exec_cmd(cmd.fileManager),     "Apps: File manager (yazi)")
bind(key("B"),         hl.dsp.exec_cmd(cmd.browserPersonal), "Apps: Browser (personal profile)")
bind(key("SHIFT + B"), hl.dsp.exec_cmd(cmd.browserWork),     "Apps: Browser (work profile)")
bind(key("E"),         hl.dsp.exec_cmd(cmd.editor),          "Apps: Editor")
bind(key("M"),         hl.dsp.exec_cmd(cmd.music),           "Apps: Music (spotify_player)")
bind(key("SHIFT + C"), hl.dsp.exec_cmd(cmd.calculator),      "Apps: Calculator")

-- Session
bind(key("slash"),          hl.dsp.exec_cmd(cmd.cheatsheet), "Session: Show this cheat sheet")
bind(key("L"),              hl.dsp.exec_cmd(cmd.lock),       "Session: Lock screen")
bind(key("SHIFT + Escape"), hl.dsp.exec_cmd(cmd.logout),     "Session: Log out")
bind(key("N"),              hl.dsp.exec_cmd(cmd.notifications), "Session: Notification center")
bind(key("SHIFT + N"),      hl.dsp.exec_cmd(cmd.doNotDisturb),  "Session: Toggle do not disturb")
bind(key("I"),              hl.dsp.exec_cmd(cmd.quickSettings), "Session: Quick settings")
bind(key("SHIFT + I"),      hl.dsp.exec_cmd(cmd.keepAwake),     "Session: Toggle keep awake (pause auto-lock)")

-- Windows
bind(key("Q"),         hl.dsp.window.close(),                          "Windows: Close")
bind(key("SHIFT + F"), hl.dsp.window.fullscreen({ action = "toggle" }), "Windows: Toggle fullscreen")
bind(key("SHIFT + V"), hl.dsp.window.float({ action = "toggle" }),      "Windows: Toggle floating")
bind(key("P"),         hl.dsp.window.pseudo(),                          "Windows: Toggle pseudo-tiling")
bind(key("J"),         hl.dsp.layout("togglesplit"),                    "Windows: Toggle split direction")
for _, d in ipairs({ "left", "right", "up", "down" }) do
    bind(key(d),             hl.dsp.focus({ direction = d }),       "Windows: Focus " .. d)
    bind(key("SHIFT + " .. d), hl.dsp.window.move({ direction = d }), "Windows: Move " .. d)
end
-- Mouse binds: 0.55 inferred them from the key; 0.57+ requires the flag.
bind(key("mouse:272"), hl.dsp.window.drag(),   "Windows: Move with mouse",   { mouse = true })
bind(key("mouse:273"), hl.dsp.window.resize(), "Windows: Resize with mouse", { mouse = true })

-- Resize mode: arrows resize the active window, Esc/Enter leave the mode.
bind(key("R"), hl.dsp.submap("resize"), "Resize: Resize mode (arrows, Esc to exit)")
submap("resize", function()
    local step = { repeating = true }
    bind("right",  hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), "Resize: Wider",   step)
    bind("left",   hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), "Resize: Narrower", step)
    bind("down",   hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), "Resize: Taller",  step)
    bind("up",     hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), "Resize: Shorter", step)
    bind("Escape", hl.dsp.submap("reset"), "Resize: Leave resize mode")
    bind("Return", hl.dsp.submap("reset"), "Resize: Leave resize mode")
end)

-- Workspaces 1-10 (key 0 is workspace 10); one cheat-sheet line per pair.
for i = 1, 10 do
    local k = tostring(i % 10)
    local first = i == 1
    bind(key(k),              hl.dsp.focus({ workspace = i }),
         first and "Workspaces: Go to workspace 1-10 (keys 1..0)" or nil, { list_only = true })
    bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }),
         first and "Workspaces: Move window to workspace 1-10 (keys 1..0)" or nil, { list_only = true })
end
bind(key("S"),            hl.dsp.workspace.toggle_special("magic"),            "Workspaces: Toggle scratchpad")
bind(key("SHIFT + S"),    hl.dsp.window.move({ workspace = "special:magic" }), "Workspaces: Move window to scratchpad")
bind(key("CTRL + right"), hl.dsp.focus({ workspace = "e+1" }),                 "Workspaces: Next")
bind(key("CTRL + left"),  hl.dsp.focus({ workspace = "e-1" }),                 "Workspaces: Previous")
bind(key("mouse_up"),     hl.dsp.focus({ workspace = "e+1" }),                 "Workspaces: Next")
bind(key("mouse_down"),   hl.dsp.focus({ workspace = "e-1" }),                 "Workspaces: Previous")

-- Tools
bind(key("V"),         hl.dsp.exec_cmd(cmd.clipboard),   "Tools: Clipboard history")
bind(key("SHIFT + P"), hl.dsp.exec_cmd(cmd.colorPicker), "Tools: Color picker (copies hex)")
bind(key("T"),         hl.dsp.exec_cmd(cmd.shotClip),    "Screenshots: Region to clipboard")
bind(key("SHIFT + T"), hl.dsp.exec_cmd(cmd.shotEdit),    "Screenshots: Region to editor (swappy)")
bind(key("CTRL + T"),  hl.dsp.exec_cmd(cmd.shotSave),    "Screenshots: Region to ~/Pictures/Screenshots")
bind("Print",          hl.dsp.exec_cmd(cmd.shotScreen),  "Screenshots: Whole monitor to ~/Pictures/Screenshots")

-- Media, volume and brightness keys (work when locked; volume/brightness repeat)
local held = { locked = true, repeating = true }
local locked = { locked = true }
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(cmd.volUp),      "Media: Volume up",        held)
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(cmd.volDown),    "Media: Volume down",      held)
bind("XF86AudioMute",         hl.dsp.exec_cmd(cmd.volMute),    "Media: Mute",             held)
bind("XF86AudioMicMute",      hl.dsp.exec_cmd(cmd.micMute),    "Media: Mute microphone",  held)
bind("XF86AudioPlay",         hl.dsp.exec_cmd(cmd.playPause),  "Media: Play/pause",       locked)
bind("XF86AudioPause",        hl.dsp.exec_cmd(cmd.playPause),  "Media: Play/pause",       locked)
bind("XF86AudioNext",         hl.dsp.exec_cmd(cmd.next),       "Media: Next track",       locked)
bind("XF86AudioPrev",         hl.dsp.exec_cmd(cmd.prev),       "Media: Previous track",   locked)
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(cmd.brightUp),   "Media: Brightness up",    held)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(cmd.brightDown), "Media: Brightness down",  held)

-- Write the bind registry (see bind() above) for the launcher. Skipped when
-- there's no runtime dir (the flake check's --verify-config).
do
    local function str(s)
        if s == nil then return "null" end
        return '"' .. (tostring(s):gsub('[%c"\\]', function(c)
            if c == '"' or c == "\\" then return "\\" .. c end
            return string.format("\\u%04x", c:byte())
        end)) .. '"'
    end
    local dir = os.getenv("XDG_RUNTIME_DIR")
    local f = dir and io.open(dir .. "/gentle-binds.json", "w")
    if f then
        local rows = {}
        for i, b in ipairs(registry) do
            rows[i] = string.format('{"desc":%s,"keys":%s,"exec":%s,"run":%s}',
                str(b.desc), str(b.keys), str(b.exec), tostring(b.run))
        end
        f:write("[\n" .. table.concat(rows, ",\n") .. "\n]\n")
        f:close()
    end
end

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

-- No auto-lock/screen-off while any window is fullscreen (videos, presentations).
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Floating dialogs and small utilities
hl.window_rule({ name = "float-modal-dialogs", match = { modal = true },                             float = true, center = true })
hl.window_rule({ name = "float-file-pickers",  match = { class = "^(xdg-desktop-portal-gtk)$" },       float = true, center = true })
hl.window_rule({ name = "float-calculator",    match = { class = "^(org.gnome.Calculator)$" },         float = true })
hl.window_rule({ name = "float-pavucontrol",   match = { class = "^(org.pulseaudio.pavucontrol)$" },   float = true })
hl.window_rule({ name = "float-bluetooth",     match = { class = "^(\\.?blueman-manager(-wrapped)?)$" }, float = true, center = true })
hl.window_rule({ name = "float-saml-tracer",   match = { initial_title = "^(_crx_mpdajninpobndbfcldcmbpnnbhibjmch)$" }, float = true })
hl.window_rule({ name = "float-ssh-askpass",   match = { title = "^(OpenSSH Authentication Passphrase request)$" },     float = true })

-- Polkit password prompt: never hidden behind windows or on another workspace.
-- Matched by title: its class is empty (Qt derives it from the NixOS wrapper
-- name ".hyprpolkitagent-wrapped", whose basename before the dot is "").
hl.window_rule({ name = "polkit-prompt", match = { title = "^(Hyprland Polkit Agent)$" },
                 float = true, center = true, pin = true, dim_around = true })

-- Windows that should not be transparent
local opaque = "1.0 override 1.0 override"
-- Streaming tabs (window title of the active tab) in Firefox / Chromium.
-- Rule regexes must match the WHOLE string (RE2::FullMatch), hence the `.*`.
hl.window_rule({ name = "opaque-streaming",
                 match = { class = "^(firefox|chromium-browser)$", title = "^(Hulu \\| Watch.*|.* - YouTube.*|Netflix.*)$" },
                 opacity = opaque })
hl.window_rule({ name = "opaque-vlc",      match = { class = "^(vlc)$", initial_title = "^(VLC media player)$" }, opacity = opaque })
hl.window_rule({ name = "opaque-inkscape", match = { class = "^(org.inkscape.Inkscape)$" }, opacity = opaque })
hl.window_rule({ name = "opaque-freetube", match = { class = "^(FreeTube)$" }, opacity = opaque })


---------------------
---- LAYER RULES ----
---------------------

-- Blur behind the translucent overlays. ignore_alpha keeps fully transparent
-- pixels (rounded corners, the launcher's unused area) from being blurred into a grey box.
-- gentle-* are the Quickshell shell's layers (quickshell/shell).
for _, ns in ipairs({ "gentle-bar", "gentle-panel", "gentle-notifications", "gentle-launcher" }) do
    hl.layer_rule({ name = "blur-" .. ns, match = { namespace = "^(" .. ns .. ")$" }, blur = true, ignore_alpha = 0.5 })
end

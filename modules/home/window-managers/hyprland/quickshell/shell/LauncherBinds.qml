pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Hyprland binds, from the registry hyprland.lua writes at config load
// ($XDG_RUNTIME_DIR/gentle-binds.json): [{ desc, keys, exec, run }].
Singleton {
    id: root

    // [{ desc, category, text, keys: ["Super", "E"], exec, runnable }]
    property var binds: []
    // Categories in registry order (the cheat sheet's tabs).
    readonly property var categories: binds.map(b => b.category).filter((c, i, all) => all.indexOf(c) === i)

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/gentle-binds.json"
        watchChanges: true
        // Missing until Hyprland has loaded the config.
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let raw;
            try {
                raw = JSON.parse(text());
            } catch (e) {
                // Caught mid-write by a config reload; the next change event
                // brings the complete file.
                return;
            }
            root.binds = raw.map(b => {
                const m = /^([^:]+):\s*(.*)$/.exec(b.desc);
                return {
                    desc: b.desc,
                    category: m ? m[1] : "Other",
                    text: m ? m[2] : b.desc,
                    keys: root.caps(b.keys),
                    exec: b.exec,
                    runnable: b.run
                };
            });
        }
    }

    readonly property var keyNames: ({
        "SUPER": "Super", "SHIFT": "Shift", "CTRL": "Ctrl", "ALT": "Alt",
        "slash": "/", "Escape": "Esc", "Return": "Enter", "Print": "PrtSc",
        "left": "←", "right": "→", "up": "↑", "down": "↓",
        "mouse:272": "Left drag", "mouse:273": "Right drag",
        "mouse_up": "Scroll ↑", "mouse_down": "Scroll ↓"
    })

    // "SUPER + SHIFT + Escape" -> ["Super", "Shift", "Esc"]
    function caps(keys) {
        return (keys ?? "").split("+").map(k => k.trim()).filter(k => k !== "")
            .map(k => keyNames[k] ?? k.replace(/^XF86/, ""));
    }

    // Program name of a command line: "/nix/store/…/bin/kitty fish" -> "kitty".
    function program(command) {
        const first = (command ?? "").trim().split(/\s+/)[0] ?? "";
        return first.replace(/^["']|["']$/g, "").split("/").pop();
    }

    // The first bind that launches this desktop entry, or null.
    function forApp(entry) {
        const names = [program((entry.command ?? [])[0]), entry.id.replace(/\.desktop$/, ""),
            entry.startupClass].filter(n => n).map(n => n.toLowerCase());
        return binds.find(b => b.exec && names.includes(program(b.exec).toLowerCase())) ?? null;
    }

    function byDesc(desc) {
        return binds.find(b => b.desc === desc) ?? null;
    }

    function item(bind, m) {
        return {
            key: "bind:" + bind.desc,
            kind: "keybind",
            title: bind.text,
            subtitle: bind.category,
            titleHtml: m ? Fuzzy.highlight(bind.text, m.positions, Style.accent) : "",
            glyph: Icons.keyboard,
            keys: bind.keys,
            disabled: !bind.runnable,
            run: () => run(bind)
        };
    }

    // One item per description (a bind on two keys shows the first).
    function search(query) {
        const out = [];
        const seen = {};
        for (const bind of binds) {
            if (seen[bind.desc])
                continue;
            seen[bind.desc] = true;
            const m = Fuzzy.best(query, [[bind.text, 1], [bind.category, 0.5, true]]);
            if (!m)
                continue;
            const it = item(bind, m.field === 0 ? m : null);
            it.score = m.score;
            out.push(it);
        }
        return out;
    }

    // For recent items: "bind:<desc>" -> item, or null if the bind is gone.
    function byKey(key) {
        const bind = byDesc(key.slice(5));
        return bind ? item(bind, null) : null;
    }

    // Lua string literal for the dispatch call.
    function lua(s) {
        return '"' + s.replace(/[\\"]/g, c => "\\" + c).replace(/\n/g, "\\n") + '"';
    }

    // `dispatch X` runs hl.dispatch(X) on Hyprland 0.57's Lua config.
    function run(bind) {
        if (bind?.runnable)
            Hyprland.dispatch(`gentleBinds[${lua(bind.desc)}]`);
    }
}

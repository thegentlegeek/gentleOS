pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Power mode: the session actions from Settings (as SessionButtons uses).
// Log out, reboot and shut down take a second Enter.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock", label: "Lock", glyph: Icons.lock, command: Settings.lock, confirm: false },
        { id: "suspend", label: "Suspend", glyph: Icons.sleep, command: Settings.suspend, confirm: false },
        { id: "logout", label: "Log out", glyph: Icons.logout, command: Settings.logout, confirm: true },
        { id: "reboot", label: "Reboot", glyph: Icons.reboot, command: Settings.reboot, confirm: true },
        { id: "poweroff", label: "Shut down", glyph: Icons.power, command: Settings.poweroff, confirm: true }
    ]
    // Id of the action waiting for its second Enter.
    property string confirming: ""
    property real uptime: 0

    readonly property string uptimeText: {
        const m = Math.floor(uptime / 60);
        const d = Math.floor(m / 1440), h = Math.floor(m / 60) % 24;
        return "up " + (d > 0 ? `${d} d ${h} h` : h > 0 ? `${h} h ${m % 60} min` : `${m % 60} min`);
    }
    readonly property string confirmText: {
        const a = actions.find(a => a.id === confirming);
        if (!a)
            return "";
        const n = Hyprland.toplevels.values.length;
        return a.id === "logout" ? `Log out closes ${n} open window${n === 1 ? "" : "s"}.`
            : `${a.label} closes ${n} open window${n === 1 ? "" : "s"}.`;
    }

    function reload() {
        confirming = "";
        uptimeFile.reload();
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text())
    }

    function item(a, m) {
        return {
            key: "power:" + a.id,
            kind: "power",
            power: a,
            title: a.label,
            titleHtml: m ? Fuzzy.highlight(a.label, m.positions, Style.accent) : "",
            glyph: a.glyph,
            keepOpen: a.confirm && confirming !== a.id,
            run: () => {
                if (a.confirm && confirming !== a.id) {
                    confirming = a.id;
                    return;
                }
                confirming = "";
                Quickshell.execDetached(a.command);
            }
        };
    }

    function search(query) {
        const out = [];
        for (const a of actions) {
            const m = query ? Fuzzy.match(query, a.label) : null;
            if (query && !m)
                continue;
            out.push(item(a, m));
        }
        return out;
    }

    // For recent items: "power:<id>" -> item. Confirmation still applies.
    function byKey(key) {
        const a = actions.find(a => a.id === key.slice(6));
        return a ? item(a, null) : null;
    }
}

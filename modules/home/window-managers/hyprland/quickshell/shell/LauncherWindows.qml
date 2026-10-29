pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import "fuzzy.js" as Fuzzy

// Windows mode: open windows grouped by workspace. Enter focuses one,
// Shift+1…0 moves it to a workspace, Ctrl+Q closes it.
Singleton {
    id: root

    function address(toplevel) {
        const a = toplevel.address;
        return a.startsWith("0x") ? a : "0x" + a;
    }

    function appOf(toplevel) {
        const cls = toplevel.lastIpcObject?.class ?? toplevel.wayland?.appId ?? "";
        const entry = cls ? DesktopEntries.heuristicLookup(cls) : null;
        return { cls, entry, name: entry?.name ?? cls };
    }

    function workspaceLabel(ws) {
        if (!ws)
            return "";
        return ws.name.startsWith("special:") ? "Scratchpad" : `Workspace ${ws.name}`;
    }

    function focus(toplevel) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address(toplevel)}" })`);
    }

    // Focus first, then move: Hyprland's move acts on the focused window.
    // One eval so the two can't be reordered.
    function moveTo(toplevel, workspace) {
        Quickshell.execDetached(["hyprctl", "eval",
            `hl.dispatch(hl.dsp.focus({ window = "address:${address(toplevel)}" })) hl.dispatch(hl.dsp.window.move({ workspace = ${workspace} }))`]);
    }

    function item(toplevel, m) {
        const app = appOf(toplevel);
        const ws = toplevel.workspace;
        return {
            kind: "window",
            toplevel: toplevel,
            title: toplevel.title,
            titleHtml: m?.field === 0 ? Fuzzy.highlight(toplevel.title, m.positions, Style.accent) : "",
            subtitle: app.name,
            icon: app.entry ? LauncherApps.iconSource(app.entry.icon) : "",
            glyph: Icons.windows,
            badge: ws ? (ws.name.startsWith("special:") ? "scratch" : `ws ${ws.name}`) : "",
            run: () => focus(toplevel),
            keyActions: {
                "ctrl+q": () => toplevel.wayland?.close()
            }
        };
    }

    // Flat matches, best first (universal search).
    function search(query) {
        const out = [];
        for (const t of Hyprland.toplevels.values) {
            const app = appOf(t);
            const m = Fuzzy.best(query, [[t.title, 1], [app.name, 0.8], [app.cls, 0.6]]);
            if (!m)
                continue;
            const it = item(t, m);
            it.score = m.score;
            out.push(it);
        }
        return out.sort((a, b) => b.score - a.score);
    }

    // Grouped by workspace, numbered workspaces first, then the scratchpad.
    function rows(query) {
        const matches = query ? search(query) : Hyprland.toplevels.values.map(t => item(t, null));
        const order = ws => !ws ? 1e9 : ws.name.startsWith("special:") ? 1e8 : ws.id;
        matches.sort((a, b) => order(a.toplevel.workspace) - order(b.toplevel.workspace) || (b.score ?? 0) - (a.score ?? 0));
        const rows = [];
        let last = null;
        for (const it of matches) {
            const label = workspaceLabel(it.toplevel.workspace);
            if (label !== last) {
                rows.push({ header: true, title: label });
                last = label;
            }
            it.badge = "";
            it.compact = false;
            rows.push(it);
        }
        return rows;
    }
}

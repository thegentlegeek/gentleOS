pragma Singleton

import Quickshell
import QtQuick
import "fuzzy.js" as Fuzzy

// Launcher items for desktop applications. Apps start through `uwsm app` so
// they get their own systemd scope, like the rest of the shell's launches.
Singleton {
    id: root

    // A snapshot taken once the list settles: DesktopEntries scans lazily and
    // adds apps one at a time, and re-running every search per app blocked the
    // shell long enough to drop keystrokes.
    property var entries: []

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            refresh.restart();
        }
    }

    Timer {
        id: refresh
        interval: 250
        onTriggered: root.entries = DesktopEntries.applications.values.filter(e => !e.noDisplay)
    }

    // Start the scan at shell startup rather than on the first search.
    Component.onCompleted: refresh.start()

    function iconSource(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true);
    }

    function desktopId(entry) {
        return entry.id.endsWith(".desktop") ? entry.id : entry.id + ".desktop";
    }

    // action: one of entry.actions, or undefined for the app itself.
    function launch(entry, action) {
        if (entry.runInTerminal)
            Quickshell.execDetached([Settings.uwsm, "app", "--"].concat(Settings.terminal, (action ?? entry).command));
        else
            Quickshell.execDetached([Settings.uwsm, "app", "--", desktopId(entry) + (action ? ":" + action.id : "")]);
    }

    function subtitleOf(entry) {
        return entry.comment || entry.genericName || "";
    }

    // m: a Fuzzy.best() result over the fields in search(), for highlighting.
    function item(entry, m) {
        const bind = LauncherBinds.forApp(entry);
        const subtitle = subtitleOf(entry);
        return {
            key: "app:" + entry.id,
            kind: "app",
            section: "Apps",
            title: entry.name,
            subtitle: subtitle,
            titleHtml: m?.field === 0 ? Fuzzy.highlight(entry.name, m.positions, Style.accent) : "",
            subtitleHtml: m?.field === 1 ? Fuzzy.highlight(subtitle, m.positions, Style.accent) : "",
            icon: iconSource(entry.icon),
            glyph: Icons.app,
            keys: bind ? bind.keys : [],
            actions: entry.actions.map(a => ({
                title: a.name,
                icon: iconSource(a.icon || entry.icon),
                glyph: Icons.app,
                run: () => launch(entry, a)
            })),
            run: () => launch(entry)
        };
    }

    function search(query) {
        const out = [];
        for (const entry of entries) {
            const m = Fuzzy.best(query, [
                [entry.name, 1],
                [subtitleOf(entry), 0.6],
                [entry.genericName, 0.7],
                [Array.from(entry.keywords).join(" "), 0.6],
                [LauncherBinds.program(entry.execString), 0.7]
            ]);
            if (!m)
                continue;
            const it = item(entry, m);
            it.score = m.score;
            out.push(it);
        }
        return out;
    }

    // For recent items: "app:<id>" -> item, or null if the app is gone.
    function byKey(key) {
        const entry = DesktopEntries.byId(key.slice(4));
        return entry ? item(entry, null) : null;
    }
}

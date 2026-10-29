pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The launcher (Launcher.qml): its mode, query and result rows, and the
// recent-use counts that rank results and fill the empty state.
//
// A row is either a section header { header: true, title } or an item:
//   { key, kind, title, subtitle, titleHtml, subtitleHtml, icon, glyph, keys,
//     badge, hint, actions, disabled, run(alt) }
// Items with a `key` are counted when run. run(alt) gets alt = Shift held.
Singleton {
    id: root

    readonly property bool open: ShellState.openPanel === "launcher"
    // "all" or one of modes[].mode.
    property string mode: "all"
    property string query: ""
    // The item whose actions (Tab) are listed instead of the results.
    property var actionsOf: null

    readonly property var modes: [
        { prefix: ":", mode: "clipboard", label: "clipboard", title: "Clipboard", glyph: Icons.clipboard, placeholder: "Search clipboard…", width: 880 },
        { prefix: "?", mode: "keybinds", label: "keys", title: "Keybinds", glyph: Icons.keyboard, placeholder: "Search by action or key…", width: 1000 },
        { prefix: "=", mode: "calc", label: "calc", title: "Calc", glyph: Icons.calculator, placeholder: "Type an expression…", width: 720 },
        { prefix: "@", mode: "windows", label: "windows", title: "Windows", glyph: Icons.windows, placeholder: "Search open windows…", width: 880 },
        { prefix: ".", mode: "emoji", label: "emoji", title: "Emoji", glyph: Icons.emoji, placeholder: "Search by name…", width: 720 },
        { prefix: ">", mode: "run", label: "run", title: "Run", glyph: Icons.terminal, placeholder: "Command to run…", width: 720 },
        { prefix: "!", mode: "power", label: "power", title: "Power", glyph: Icons.power, placeholder: "Lock, suspend, reboot…", width: 720 }
    ]
    readonly property var currentMode: modes.find(m => m.mode === mode) ?? null
    readonly property int width: currentMode?.width ?? 720

    readonly property var rows: {
        if (actionsOf)
            return [{ header: true, title: actionsOf.title }].concat(actionsOf.actions);
        const q = query.trim();
        if (mode === "all")
            return q === "" ? home() : universal(q);
        return [];
    }

    // Load the app list and bind registry at startup, not on the first search.
    Component.onCompleted: {
        LauncherApps.entries;
        LauncherBinds.binds;
    }

    function show(m) {
        mode = m || "all";
        query = "";
        actionsOf = null;
        ShellState.openPanel = "launcher";
    }

    function toggle() {
        if (open)
            close();
        else
            show("all");
    }

    function close() {
        ShellState.close("launcher");
    }

    // Text typed into the search field. A mode prefix typed into the empty
    // field switches to that mode instead of searching for it.
    function input(text) {
        actionsOf = null;
        if (mode === "all" && query === "" && text.length > 0) {
            const m = modes.find(m => m.prefix === text[0]);
            if (m) {
                mode = m.mode;
                query = text.slice(1);
                return;
            }
        }
        query = text;
    }

    // Backspace in the empty field.
    function back() {
        if (actionsOf)
            actionsOf = null;
        else if (mode !== "all")
            mode = "all";
    }

    function activate(item, alt) {
        if (!item || item.header || item.disabled)
            return;
        if (item.key)
            record(item.key);
        if (!item.keepOpen)
            close();
        item.run(alt);
    }

    function showActions(item) {
        if (item?.actions?.length)
            actionsOf = item;
    }

    // ---- Results ----

    function section(title, items, limit) {
        if (items.length === 0)
            return [];
        return [{ header: true, title }].concat(items.slice(0, limit));
    }

    // Provider results ranked by match score plus recent use.
    function ranked(items) {
        for (const it of items)
            it.score = (it.score ?? 0) + Math.min(frecency(it.key), 10) * 40;
        return items.sort((a, b) => b.score - a.score);
    }

    function universal(q) {
        return [].concat(
            section("Apps", ranked(LauncherApps.search(q)), 5),
            section("Keybinds", ranked(LauncherBinds.search(q)), 3),
            [webItem(q)]
        );
    }

    function home() {
        return section("Recent", recentItems(), 7);
    }

    function webItem(q) {
        const url = Settings.searchUrl.replace("%s", encodeURIComponent(q));
        return {
            kind: "web",
            title: `Search the web for “${q}”`,
            glyph: Icons.web,
            hint: "Personal · ⇧↵ Work",
            compact: true,
            run: alt => Quickshell.execDetached((alt ? Settings.browserWork : Settings.browserPersonal).concat([url]))
        };
    }

    // ---- Recent use ----

    function frecency(key) {
        const r = store.recent[key];
        if (!r)
            return 0;
        const days = (Date.now() - r.last) / 86400000;
        return r.count * Math.pow(0.5, days / 7);
    }

    function record(key) {
        const recent = Object.assign({}, store.recent);
        const r = recent[key] ?? { count: 0 };
        recent[key] = { count: r.count + 1, last: Date.now() };
        // Keep the 200 most recent.
        const keys = Object.keys(recent).sort((a, b) => recent[b].last - recent[a].last);
        for (const k of keys.slice(200))
            delete recent[k];
        store.recent = recent;
        storeFile.writeAdapter();
    }

    // The recent items that still exist, most used first.
    function recentItems() {
        const keys = Object.keys(store.recent).sort((a, b) => frecency(b) - frecency(a));
        const out = [];
        for (const key of keys) {
            const it = resolve(key);
            if (it) {
                it.compact = true;
                it.label = it.kind;
                out.push(it);
            }
            if (out.length >= 7)
                break;
        }
        return out;
    }

    function resolve(key) {
        if (key.startsWith("app:"))
            return LauncherApps.byKey(key);
        if (key.startsWith("bind:"))
            return LauncherBinds.byKey(key);
        return null;
    }

    FileView {
        id: storeFile
        path: Quickshell.statePath("launcher.json")
        // Missing on first run; created by the handler below.
        printErrors: false
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            // key -> { count, last (ms since epoch) }
            property var recent: ({})
        }
    }
}

pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

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
    // Keybinds mode: the category shown ("" for all), cycled with Tab.
    property string bindCategory: ""
    // Emoji mode: "emoji", "nerd" or "symbols", cycled with Tab.
    property string emojiTab: "emoji"

    readonly property var modes: [
        { prefix: ":", mode: "clipboard", label: "clipboard", title: "Clipboard", glyph: Icons.clipboard, placeholder: "Search clipboard…", width: 880, split: true },
        { prefix: "?", mode: "keybinds", label: "keys", title: "Keybinds", glyph: Icons.keyboard, placeholder: "Search keybinds…", width: 1000,
            hints: [[["↵"], "run the selected bind"], [["⇥"], "next category"]] },
        { prefix: "=", mode: "calc", label: "calc", title: "Calc", glyph: Icons.calculator, placeholder: "Type an expression…", width: 720,
            hints: [[["↵"], "copy"], [["⇥"], "cycle formats"], [["↓"], "history"]] },
        { prefix: "@", mode: "windows", label: "windows", title: "Windows", glyph: Icons.windows, placeholder: "Search open windows…", width: 880, split: true },
        { prefix: ".", mode: "emoji", label: "emoji", title: "Emoji", glyph: Icons.emoji, placeholder: "Search by name…", width: 760 },
        { prefix: ">", mode: "run", label: "run", title: "Run", glyph: Icons.terminal, placeholder: "Command to run…", width: 720,
            hints: [[["↵"], "run"], [["Ctrl", "T"], "kitty / background"], [["⇥"], "complete"]] },
        { prefix: "!", mode: "power", label: "power", title: "Power", glyph: Icons.power, placeholder: "Lock, suspend, reboot…", width: 720 }
    ]
    readonly property var currentMode: modes.find(m => m.mode === mode) ?? null
    readonly property int width: currentMode?.width ?? 720

    readonly property var rows: {
        if (actionsOf)
            return [{ header: true, title: actionsOf.title }].concat(actionsOf.actions);
        const q = query.trim();
        switch (mode) {
        case "all":
            return q === "" ? home() : universal(q);
        case "clipboard":
            return LauncherClipboard.search(q);
        case "keybinds":
            return keybindRows(q);
        case "calc":
            return calcHistoryRows();
        case "windows":
            return LauncherWindows.rows(q);
        case "run":
            return LauncherRun.rows(query);
        case "power":
            return LauncherPower.search(q);
        case "emoji":
            return LauncherEmoji.rows(emojiTab, q);
        }
        return [];
    }

    onOpenChanged: {
        if (!open)
            return;
        LauncherClipboard.reload();
        LauncherRun.reload();
        LauncherPower.reload();
        Hyprland.refreshToplevels();
    }

    onQueryChanged: {
        if (mode === "calc" || (mode === "all" && LauncherCalc.looksLikeMath(query)))
            LauncherCalc.evaluate(query);
    }

    onModeChanged: {
        if (mode === "calc")
            LauncherCalc.evaluate(query);
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
        bindCategory = "";
        emojiTab = "emoji";
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
        // Calc mode with no history row selected: copy the result.
        if (!item && mode === "calc" && LauncherCalc.result !== "") {
            close();
            LauncherCalc.copy();
            return;
        }
        if (!item || item.header || item.disabled)
            return;
        // Items that stay open (a power action's first Enter) haven't run yet.
        if (item.key && !item.keepOpen)
            record(item.key);
        if (!item.keepOpen)
            close();
        item.run(alt);
    }

    // Tab: the next keybind category or calc format, completes a command, or
    // lists the selected item's actions.
    function tab(item) {
        if (mode === "keybinds") {
            const cats = [""].concat(LauncherBinds.categories);
            bindCategory = cats[(cats.indexOf(bindCategory) + 1) % cats.length];
        } else if (mode === "calc") {
            LauncherCalc.cycle();
        } else if (mode === "emoji") {
            const tabs = LauncherEmoji.tabs.map(t => t[0]);
            emojiTab = tabs[(tabs.indexOf(emojiTab) + 1) % tabs.length];
        } else if (mode === "run") {
            if (item?.kind === "command")
                query = item.title;
        } else if (item?.actions?.length) {
            actionsOf = item;
        }
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
        const calc = LauncherCalc.looksLikeMath(q) && LauncherCalc.expression === q ? LauncherCalc.item() : null;
        return [].concat(
            calc ? [calc] : [],
            section("Apps", ranked(LauncherApps.search(q)), 5),
            section("Windows", LauncherWindows.search(q), 3),
            section("Keybinds", ranked(LauncherBinds.search(q)), 3),
            section("Clipboard", LauncherClipboard.search(q), 3),
            [webItem(q)]
        );
    }

    function home() {
        return clipboardPeek().concat(section("Recent", recentItems(), 7));
    }

    // The newest clipboard entry, as a way into clipboard mode.
    function clipboardPeek() {
        const entry = LauncherClipboard.entries[0];
        if (!entry)
            return [];
        return [{
            kind: "peek",
            title: entry.image ? `${entry.image.type.toUpperCase()} image` : entry.text.trim(),
            label: "clipboard",
            glyph: Icons.clipboard,
            keys: [":"],
            compact: true,
            dim: true,
            // Not selected when the launcher opens; Recent's first item is.
            passive: true,
            keepOpen: true,
            run: () => {
                mode = "clipboard";
                query = "";
            }
        }];
    }

    // Calc mode's history; selecting one puts it back in the field.
    function calcHistoryRows() {
        const items = store.calcHistory.map(h => ({
            kind: "calc",
            title: h.expression,
            hint: "= " + h.result,
            glyph: Icons.history,
            compact: true,
            passive: true,
            keepOpen: true,
            run: () => {
                query = h.expression;
            }
        }));
        return section("History", items, 8);
    }

    function addCalcHistory(expression, result) {
        const history = [{ expression, result }].concat(store.calcHistory.filter(h => h.expression !== expression));
        store.calcHistory = history.slice(0, 20);
        storeFile.writeAdapter();
    }

    // Every bind, grouped by category in registry order.
    function keybindRows(q) {
        const rows = [];
        let last = null;
        for (const bind of LauncherBinds.binds) {
            if (bindCategory && bind.category !== bindCategory)
                continue;
            const m = q ? Fuzzy.best(q, [[bind.text, 1], [bind.category, 0.5, true], [bind.keys.join(" "), 0.5, true]]) : null;
            if (q && !m)
                continue;
            if (bind.category !== last) {
                rows.push({ header: true, title: bind.category });
                last = bind.category;
            }
            const it = LauncherBinds.item(bind, m?.field === 0 ? m : null);
            it.dense = true;
            rows.push(it);
        }
        return rows;
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

    // Pinned clipboard entries (cliphist ids).
    function isPinned(id) {
        return store.pins.includes(id);
    }

    // Where the launcher sits: its top edge as a fraction of the monitor height.
    readonly property real top: store.top

    function setTop(fraction) {
        store.top = fraction;
        storeFile.writeAdapter();
    }

    function togglePin(id) {
        store.pins = isPinned(id) ? store.pins.filter(p => p !== id) : store.pins.concat([id]);
        storeFile.writeAdapter();
    }

    // Recorded keys starting with `prefix`, most used first.
    function recentKeys(prefix) {
        return Object.keys(store.recent).filter(k => k.startsWith(prefix)).sort((a, b) => frecency(b) - frecency(a));
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
        if (key.startsWith("cmd:"))
            return LauncherRun.byKey(key);
        if (key.startsWith("power:"))
            return LauncherPower.byKey(key);
        if (key.startsWith("emoji:"))
            return LauncherEmoji.byKey(key);
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
            property var pins: []
            // [{ expression, result }], newest first.
            property var calcHistory: []
            // Launcher position (see `top` above).
            property real top: 0.15
        }
    }
}

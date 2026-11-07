pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Clipboard history from cliphist (services.cliphist), reloaded each time the
// launcher opens. Images are decoded to the runtime dir for thumbnails.
Singleton {
    id: root

    // [{ id, line, text, image: { size, type, width, height } | null }], newest first.
    property var entries: []
    // Entry id -> thumbnail file URL, once decoded.
    property var thumbs: ({})
    // Full text of `previewId`, decoded on demand for the preview pane.
    property string previewId: ""
    property string previewText: ""

    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/gentle-launcher"

    function reload() {
        list.running = true;
    }

    Process {
        id: list
        command: [Settings.cliphist, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const preview = line.slice(tab + 1);
                    const img = /^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/.exec(preview);
                    return {
                        id: line.slice(0, tab),
                        line: line,
                        text: preview,
                        image: img ? { size: img[1], type: img[2], width: +img[3], height: +img[4] } : null
                    };
                });
                root.decodeThumbs();
            }
        }
    }

    // `cliphist decode` reads the list line on stdin.
    function decodeCommand(line) {
        return [Settings.sh, "-c", `printf '%s' "$1" | "$2" decode`, "sh", line, Settings.cliphist];
    }

    function decodeThumbs() {
        const todo = entries.filter(e => e.image && !thumbs[e.id]).slice(0, 40);
        if (todo.length === 0 || thumbProcess.running)
            return;
        const args = [];
        for (const e of todo)
            args.push(e.line, `${thumbDir}/clip-${e.id}.${e.image.type}`);
        thumbProcess.pending = todo;
        thumbProcess.command = [Settings.sh, "-c", `dir=$1 cliphist=$2; shift 2; mkdir -p "$dir"
while [ $# -ge 2 ]; do printf '%s' "$1" | "$cliphist" decode > "$2"; shift 2; done`,
            "sh", thumbDir, Settings.cliphist].concat(args);
        thumbProcess.running = true;
    }

    Process {
        id: thumbProcess
        property var pending: []
        onExited: {
            const thumbs = Object.assign({}, root.thumbs);
            for (const e of pending)
                thumbs[e.id] = `file://${root.thumbDir}/clip-${e.id}.${e.image.type}`;
            root.thumbs = thumbs;
        }
    }

    function preview(entry) {
        if (!entry || entry.image || previewId === entry.id)
            return;
        previewId = entry.id;
        previewText = entry.text;
        previewProcess.running = false;
        previewProcess.command = decodeCommand(entry.line);
        previewProcess.running = true;
    }

    Process {
        id: previewProcess
        stdout: StdioCollector {
            // Cap what the preview pane lays out.
            onStreamFinished: root.previewText = text.slice(0, 4000)
        }
    }

    function copy(entry) {
        Quickshell.execDetached([Settings.sh, "-c", `printf '%s' "$1" | "$2" decode | "$3"`,
            "sh", entry.line, Settings.cliphist, Settings.wlCopy]);
    }

    function remove(entry) {
        Quickshell.execDetached([Settings.sh, "-c", `printf '%s' "$1" | "$2" delete`,
            "sh", entry.line, Settings.cliphist]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function kindOf(entry) {
        if (entry.image)
            return "image";
        if (/^(https?|file):\/\/\S+$/.test(entry.text.trim()))
            return "link";
        return "text";
    }

    function item(entry, m) {
        const kind = kindOf(entry);
        const pinned = LauncherState.isPinned(entry.id);
        const title = entry.image ? (entry.image.type.toUpperCase() + " image") : entry.text.trim();
        return {
            kind: "clipboard",
            entry: entry,
            title: title,
            titleHtml: m ? Fuzzy.highlight(title, m.positions, Style.accent) : "",
            subtitle: entry.image ? `Image · ${entry.image.width}×${entry.image.height} · ${entry.image.size}`
                : (kind === "link" ? "Link" : "Text") + (pinned ? " · pinned" : ""),
            glyph: kind === "image" ? Icons.image : kind === "link" ? Icons.link : Icons.textLines,
            icon: entry.image ? (thumbs[entry.id] ?? "") : "",
            badge: pinned ? Icons.pin : "",
            run: () => copy(entry),
            keyActions: {
                "ctrl+p": () => LauncherState.togglePin(entry.id),
                "ctrl+d": () => remove(entry)
            }
        };
    }

    // Best match first; with no query, pinned entries and then newest first.
    function search(query) {
        if (!query) {
            const items = entries.map(e => item(e, null));
            return items.filter(it => LauncherState.isPinned(it.entry.id))
                .concat(items.filter(it => !LauncherState.isPinned(it.entry.id)));
        }
        const out = [];
        for (const entry of entries) {
            // Substring only: entries are long, and scattered letters match most.
            const m = Fuzzy.best(query, [[entry.image ? entry.image.type + " image" : entry.text, 1, true]]);
            if (!m)
                continue;
            const it = item(entry, m);
            it.score = m.score;
            out.push(it);
        }
        return out.sort((a, b) => b.score - a.score);
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Run mode: a command line, run in kitty (kept open if it fails) or in the
// background. Suggestions come from fish history and the programs on PATH.
Singleton {
    id: root

    // Newest first.
    property var history: []
    property var programs: []
    property bool inTerminal: true

    function reload() {
        historyProcess.running = true;
        if (programs.length === 0)
            pathProcess.running = true;
    }

    Process {
        id: historyProcess
        command: [Settings.fish, "-c", "history --null --max 1000"]
        stdout: StdioCollector {
            onStreamFinished: root.history = text.split("\0").filter(c => c.trim() !== "")
        }
    }

    Process {
        id: pathProcess
        command: [Settings.sh, "-c", 'IFS=:; for d in $PATH; do ls -1 "$d" 2>/dev/null; done | sort -u']
        stdout: StdioCollector {
            onStreamFinished: root.programs = text.split("\n").filter(p => p !== "")
        }
    }

    function run(command, terminal) {
        if (terminal) {
            // Keep the window open when the command fails, so its error stays readable.
            const script = `${command}\nset -l s $status\nif test $s -ne 0\n    read -P "[exit $s] Press Enter to close "\nend`;
            Quickshell.execDetached([Settings.uwsm, "app", "--"].concat(Settings.terminal, [Settings.fish, "-c", script]));
        } else {
            Quickshell.execDetached([Settings.uwsm, "app", "--", Settings.sh, "-c", command]);
        }
    }

    function item(command, extra) {
        return Object.assign({
            key: "cmd:" + command,
            kind: "command",
            title: command,
            glyph: Icons.terminal,
            run: () => run(command, inTerminal)
        }, extra);
    }

    function rows(query) {
        const q = query.trim();
        const where = inTerminal ? "in kitty" : "in the background";
        const rows = [];
        if (q !== "")
            rows.push(item(q, { subtitle: `Run as typed ${where} · ~` }));

        // Best matches first; ties keep the newest.
        const matches = [];
        for (let i = 0; i < history.length && matches.length < 200; i++) {
            const c = history[i];
            if (c === q)
                continue;
            const m = q ? Fuzzy.best(q, [[c, 1, true]]) : { score: 0, positions: [] };
            if (m)
                matches.push({ c, m, i });
        }
        matches.sort((a, b) => b.m.score - a.m.score || a.i - b.i);
        const fromHistory = matches.slice(0, 6).map(({ c, m }) => item(c, {
            titleHtml: Fuzzy.highlight(c, m.positions, Style.accent),
            glyph: Icons.history,
            compact: true
        }));
        if (fromHistory.length > 0)
            rows.push({ header: true, title: "From fish history" });
        rows.push(...fromHistory);

        const word = q.split(/\s+/)[0];
        const onPath = word ? programs.filter(p => p.startsWith(word) && p !== q).slice(0, 4) : [];
        if (onPath.length > 0)
            rows.push({ header: true, title: "On your PATH" });
        for (const p of onPath) {
            rows.push(item(p, {
                titleHtml: Fuzzy.highlight(p, [...Array(word.length).keys()], Style.accent),
                compact: true
            }));
        }
        return rows;
    }

    // For recent items: "cmd:<command>" -> item.
    function byKey(key) {
        return item(key.slice(4), {});
    }
}

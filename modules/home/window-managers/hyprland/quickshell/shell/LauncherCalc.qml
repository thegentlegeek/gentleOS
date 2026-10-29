pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Calculator mode and universal search's math row: qalc (libqalculate), so
// units, hex and percentages work. Runs after typing pauses.
Singleton {
    id: root

    property string expression: ""
    // Result of `expression`, or "" while it's evaluating or if qalc failed.
    property string result: ""
    // The result in other formats: [{ label, value }].
    property var formats: []
    // Which of [result].concat(formats) Enter copies; Tab cycles it.
    property int format: 0

    readonly property var choices: result === "" ? [] : [{ label: "", value: result }].concat(formats)
    readonly property string chosen: choices[format]?.value ?? result

    // Only send qalc things that look like maths: it answers plain words with
    // unit soup ("foo bar" -> "6.4E-35z J·m·bits²").
    function looksLikeMath(q) {
        return /\d/.test(q) && /[-+*\/^%()=]|\bto\b|\bin\b|0x/.test(q);
    }

    function evaluate(q) {
        q = q.trim();
        if (q === expression)
            return;
        expression = q;
        result = "";
        formats = [];
        format = 0;
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            if (root.expression === "")
                return;
            qalc.running = false;
            qalc.expr = root.expression;
            qalc.command = [Settings.sh, "-c", '"$1" -t "$2"; "$1" -t "$2 to hex"; "$1" -t "$2 to sci"',
                "sh", Settings.qalc, root.expression];
            qalc.running = true;
        }
    }

    Process {
        id: qalc
        property string expr
        stdout: StdioCollector {
            onStreamFinished: {
                if (qalc.expr !== root.expression)
                    return;
                const [value, hex, sci] = text.split("\n");
                // qalc echoes unknown words back as a "result".
                if (!value || value === root.expression)
                    return;
                root.result = value;
                const formats = [];
                if (/^-?\d+$/.test(value.replace(/[ ,]/g, ""))) {
                    if (hex && hex !== value)
                        formats.push({ label: "hex", value: hex });
                    if (sci && sci !== value && sci !== hex)
                        formats.push({ label: "sci", value: sci });
                }
                root.formats = formats;
            }
        }
    }

    function cycle() {
        if (choices.length > 0)
            format = (format + 1) % choices.length;
    }

    function copy() {
        if (result === "")
            return;
        Quickshell.execDetached([Settings.wlCopy, chosen]);
        LauncherState.addCalcHistory(expression, chosen);
    }

    // Universal search's row for a query that looks like maths.
    function item() {
        if (result === "")
            return null;
        return {
            kind: "calc",
            title: "= " + result,
            subtitle: expression,
            glyph: Icons.calculator,
            hint: "copy",
            run: () => copy()
        };
    }
}

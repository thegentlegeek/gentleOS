pragma Singleton

import Quickshell
import QtQuick

// What the on-screen display (Osd.qml) shows, and for how long. Audio changes
// show it by themselves; brightness keys nudge it over IPC (`osd brightness`),
// since the backlight is only polled.
Singleton {
    id: root

    // "volume", "brightness", "mic" or "output".
    property string kind: "volume"
    property bool shown: false

    function show(k) {
        kind = k;
        shown = true;
        hide.restart();
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }

    // Pipewire reports its first values a moment after startup.
    property bool settled: false
    Timer {
        running: true
        interval: 1500
        onTriggered: root.settled = true
    }

    // A new output brings its own volume; show it as the switch only.
    property real outputChangedAt: 0

    // The quick settings slider is its own feedback.
    function react(k) {
        if (settled && ShellState.openPanel !== "quickSettings")
            show(k);
    }

    Connections {
        target: Audio

        function onVolumeChanged() {
            if (Date.now() - root.outputChangedAt > 1000)
                root.react("volume");
        }

        function onMutedChanged() {
            root.react("volume");
        }

        function onMicMutedChanged() {
            root.react("mic");
        }

        function onSinkChanged() {
            if (!Audio.sink)
                return;
            root.outputChangedAt = Date.now();
            if (root.settled)
                root.show("output");
        }
    }
}

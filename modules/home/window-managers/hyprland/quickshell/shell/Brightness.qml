pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen backlight. Hidden on machines without one.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int current: 0
    readonly property bool available: device !== "" && max > 0
    readonly property real level: available ? current / max : 0
    readonly property string icon: Icons.backlight[Math.min(8, Math.floor(level * 9))]

    function set(fraction) {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, fraction)) * 100);
        current = Math.round(pct / 100 * max);
        Quickshell.execDetached([Settings.brightnessctl, "--device=" + device, "set", pct + "%"]);
    }

    // `brightnessctl -m -c backlight info` -> "amdgpu_bl1,backlight,123,48%,255"
    Process {
        running: true
        command: [Settings.brightnessctl, "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5) {
                    root.current = parseInt(f[2]);
                    root.max = parseInt(f[4]);
                    root.device = f[0];
                }
            }
        }
    }

    // sysfs attributes don't support inotify, so poll. Also catches the
    // brightness keys and hypridle's dimming.
    FileView {
        id: brightnessFile
        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.current = parseInt(text())
    }

    Timer {
        running: root.available
        interval: 1000
        repeat: true
        onTriggered: brightnessFile.reload()
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQml
import QtQuick

// CPU usage, CPU temperature and Caps Lock, polled from /proc and /sys.
Singleton {
    id: root

    // 0..1 across all cores.
    property real cpu: 0
    property var lastCpu: null
    // Smoothed over a few samples so a short spike doesn't flash the bar.
    property real cpuAvg: 0
    readonly property bool cpuHigh: cpuAvg >= Settings.cpuWarn

    // °C, or -1 until the sensor is found. Path set in Settings (Nix).
    property string tempPath: ""
    property real temp: -1
    readonly property bool tempAvailable: tempPath !== "" && temp >= 0
    readonly property bool tempHigh: tempAvailable && temp >= Settings.tempWarn
    readonly property bool tempCritical: temp >= Settings.tempCritical

    // Used RAM, 0..1, and total in GiB.
    property real mem: 0
    property real memTotalGiB: 0

    // Any keyboard's Caps Lock LED.
    property var capsPaths: []
    property var capsStates: ({})
    readonly property bool capsLock: Object.values(capsStates).some(on => on)

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu && total > root.lastCpu.total) {
                root.cpu = 1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total);
                root.cpuAvg = root.cpuAvg * 0.6 + root.cpu * 0.4;
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => parseInt((text().match(new RegExp(`^${key}:\\s+(\\d+)`, "m")) ?? [0, 0])[1]);
            const total = kb("MemTotal"), available = kb("MemAvailable");
            if (total > 0) {
                root.mem = 1 - available / total;
                root.memTotalGiB = total / 1048576;
            }
        }
    }

    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = parseInt(text()) / 1000
    }

    Process {
        running: true
        command: [Settings.sh, "-c", 'for f in "$1"/hwmon*/"$2"; do [ -e "$f" ] && echo "$f" && break; done',
            "sh", Settings.tempHwmonDir, Settings.tempInput]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }

    Process {
        running: true
        command: [Settings.sh, "-c", "for d in /sys/class/leds/*::capslock; do [ -e \"$d\" ] && echo \"$d/brightness\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.capsPaths = text.split("\n").filter(p => p !== "")
        }
    }

    Instantiator {
        id: capsFiles
        model: root.capsPaths
        delegate: FileView {
            required property string modelData
            path: modelData
            onLoaded: {
                const states = Object.assign({}, root.capsStates);
                states[modelData] = text().trim() !== "0";
                root.capsStates = states;
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 2000
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.tempPath !== "")
                tempFile.reload();
        }
    }

    Timer {
        running: root.capsPaths.length > 0
        repeat: true
        interval: 500
        onTriggered: {
            for (let i = 0; i < capsFiles.count; i++)
                capsFiles.objectAt(i).reload();
        }
    }
}

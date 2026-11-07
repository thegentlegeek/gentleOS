import Quickshell
import Quickshell.Wayland
import QtQuick

// Left: workspaces. Center: clock, media. Right: things that need attention
// (high CPU/temperature, keep awake, notifications), tray, the status pill
// (opens quick settings) and the power menu.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 40
    color: Style.alpha(Style.base00, Style.barAlpha)

    WlrLayershell.namespace: "gentle-bar"
    WlrLayershell.layer: WlrLayer.Top

    IdleInhibitor {
        window: bar
        enabled: ShellState.caffeine
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Workspaces {}
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Pill {
            color: Style.highlight
            fg: Style.highlightText
            // 12-hour without AM/PM, as before.
            text: Qt.formatDateTime(time.date, "ddd MMM d") + "  " + Qt.formatDateTime(time.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
            tooltip: Qt.formatDateTime(time.date, "dddd, MMMM d, yyyy")
            onClicked: ShellState.toggle("calendar")

            SystemClock {
                id: time
                precision: SystemClock.Minutes
            }
        }

        MediaPill {}
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Pill {
            visible: SysStats.cpuHigh
            color: Style.base0A
            fg: Style.base00
            text: `${Icons.cpu} ${Math.round(SysStats.cpu * 100)}%`
            tooltip: "High CPU usage"
        }

        Pill {
            visible: SysStats.tempHigh
            color: SysStats.tempCritical ? Style.base08 : Style.base0A
            fg: Style.base00
            text: Icons.temperature[SysStats.tempCritical ? 2 : 1] + ` ${Math.round(SysStats.temp)}°C`
            tooltip: "CPU temperature"
        }

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            bar: bar
        }

        // Only while on; click (or SUPER+SHIFT+I, or quick settings) turns it off.
        Pill {
            visible: ShellState.caffeine
            fg: Style.base0A
            padding: 10
            text: Icons.caffeineOn
            tooltip: "Keep awake is on (auto-lock paused). Click to turn off."
            onClicked: ShellState.caffeine = false
        }

        Pill {
            visible: Notifs.history.length > 0 || Notifs.dnd
            fg: Notifs.dnd ? Style.base0A : Style.fg
            padding: 10
            text: (Notifs.dnd ? Icons.bellOff : Icons.bell) + (Notifs.history.length > 0 ? ` ${Notifs.history.length}` : "")
            tooltip: (Notifs.dnd ? "Do not disturb is on\n" : "") + "Click: notifications · Right click: do not disturb"
            onClicked: m => m.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : ShellState.toggle("notifications")
        }

        StatusPill {}

        Pill {
            color: Style.base08
            fg: Style.base00
            text: Icons.power
            tooltip: "Power menu"
            onClicked: ShellState.toggle("session")
        }
    }
}

import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick

// Same modules and colors as the old Waybar bar, plus notifications and quick
// settings buttons.
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
            id: clock

            property bool short: false

            color: Style.base0D
            text: short ? Qt.formatDateTime(time.date, "HH:mm")
                // `hh` is 24-hour unless AP is in the format; drop the AM/PM.
                : Qt.formatDateTime(time.date, "dddd, MMM d") + " • " + Qt.formatDateTime(time.date, "hh:mm AP").slice(0, 5)
            tooltip: Qt.formatDateTime(time.date, "dddd, MMMM d, yyyy")
            onClicked: short = !short

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
            visible: Audio.ready
            color: Style.base02
            text: Audio.muted ? Audio.icon : `${Audio.icon} ${Math.round(Audio.volume * 100)}%`
            tooltip: (Audio.sink?.description ?? "") + "\nClick: mixer · Right click: mute · Scroll: volume"
            onClicked: m => m.button === Qt.RightButton ? Audio.toggleMute() : ShellState.run(Settings.audioSettings)
            onScrolled: step => Audio.setVolume(Audio.volume + step * 0.05)
        }

        Pill {
            text: `${Net.icon} ${Net.label}`
            tooltip: Net.activeWifi ? `Signal ${Math.round(Net.activeWifi.signalStrength * 100)}%` : ""
            onClicked: ShellState.toggle("quickSettings")
        }

        Pill {
            color: Style.base04
            text: `${Icons.cpu} ${Math.round(SysStats.cpu * 100)}%`
        }

        Pill {
            visible: SysStats.tempAvailable
            color: SysStats.tempCritical ? Style.base08 : Style.base06
            fg: Style.base00
            text: Icons.temperature[Math.min(2, Math.floor(SysStats.temp / Settings.tempCritical * 3))] + ` ${Math.round(SysStats.temp)}°C`
        }

        Pill {
            visible: Brightness.available
            color: Style.base06
            fg: Style.base00
            text: `${Brightness.icon} ${Math.round(Brightness.level * 100)}%`
            onScrolled: step => Brightness.set(Brightness.level + step * 0.05)
        }

        // Only while Caps Lock is on (Waybar showed it permanently).
        Pill {
            visible: SysStats.capsLock
            color: Style.base05
            fg: Style.base00
            text: `${Icons.capsLock} Caps`
        }

        Pill {
            id: battery

            readonly property UPowerDevice dev: UPower.displayDevice
            readonly property bool charging: dev.state === UPowerDeviceState.Charging
            readonly property bool full: dev.state === UPowerDeviceState.FullyCharged
            readonly property bool low: UPower.onBattery && dev.percentage <= 0.15
            property bool showTime: false

            function hm(seconds) {
                const m = Math.round(seconds / 60);
                return `${Math.floor(m / 60)}h ${m % 60}m`;
            }

            visible: dev.isLaptopBattery
            color: low ? Style.base08 : Style.base04
            text: {
                const pct = Math.round(dev.percentage * 100);
                const icon = charging ? Icons.charging
                    : !UPower.onBattery && !full ? Icons.plugged
                    : Icons.battery[Math.min(4, Math.floor(dev.percentage * 5))];
                if (showTime && (dev.timeToEmpty > 0 || dev.timeToFull > 0))
                    return `${icon} ${hm(charging ? dev.timeToFull : dev.timeToEmpty)}`;
                return `${icon} ${pct}%`;
            }
            tooltip: charging && dev.timeToFull > 0 ? `${hm(dev.timeToFull)} until full`
                : UPower.onBattery && dev.timeToEmpty > 0 ? `${hm(dev.timeToEmpty)} remaining`
                : ""
            onClicked: showTime = !showTime
        }

        Pill {
            readonly property var order: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]

            text: PowerProfiles.profile === PowerProfile.Performance ? Icons.profilePerformance
                : PowerProfiles.profile === PowerProfile.PowerSaver ? Icons.profileSaver
                : Icons.profileBalanced
            tooltip: "Power profile: " + PowerProfile.toString(PowerProfiles.profile)
            onClicked: PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length]
        }

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            bar: bar
        }

        Pill {
            color: "transparent"
            padding: 8
            text: ShellState.caffeine ? Icons.caffeineOn : Icons.caffeineOff
            tooltip: ShellState.caffeine ? "Auto-lock paused" : "Auto-lock on"
            onClicked: ShellState.caffeine = !ShellState.caffeine
        }

        Pill {
            text: (Notifs.dnd ? Icons.bellOff : Icons.bell) + (Notifs.history.length > 0 ? ` ${Notifs.history.length}` : "")
            tooltip: "Notifications · Right click: do not disturb"
            onClicked: m => m.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : ShellState.toggle("notifications")
        }

        Pill {
            text: Icons.tune
            tooltip: "Quick settings"
            onClicked: ShellState.toggle("quickSettings")
        }

        Pill {
            color: Style.base08
            fg: Style.base00
            text: Icons.power
            tooltip: "Power menu"
            onClicked: ShellState.toggle("session")
        }
    }
}

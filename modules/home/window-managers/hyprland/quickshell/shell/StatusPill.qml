import Quickshell.Bluetooth
import QtQuick

// Volume, network, Bluetooth and battery at a glance. Opens quick settings;
// scrolling changes the volume.
Pill {
    id: root

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter?.enabled ?? false
    readonly property var btConnected: btAdapter ? btAdapter.devices.values.filter(d => d.connected) : []

    tooltip: [
        Audio.ready ? (Audio.muted ? "Volume: muted" : `Volume: ${Math.round(Audio.volume * 100)}%`) : "",
        Net.wiredDevice ? `Wired: ${Net.wiredDevice.name}`
            : Net.activeWifi ? `Wi-Fi: ${Net.activeWifi.name} (${Math.round(Net.activeWifi.signalStrength * 100)}%)`
            : "Network: disconnected",
        btOn ? `Bluetooth: ${btConnected.map(d => d.name).join(", ") || "on"}` : "",
        Battery.present ? `Battery: ${Battery.percent}%${Battery.status ? " · " + Battery.status : ""}` : "",
    ].filter(l => l !== "").join("\n")

    onClicked: ShellState.toggle("quickSettings")
    onScrolled: step => Audio.setVolume(Audio.volume + step * 0.05)

    Row {
        spacing: 12

        BarText {
            visible: Audio.ready
            text: Audio.icon
            color: Audio.muted ? Style.muted : Style.fg
        }

        BarText {
            text: Net.icon
            color: Net.wiredDevice || Net.activeWifi ? Style.fg : Style.base0A
        }

        BarText {
            visible: root.btOn
            text: Icons.bluetooth
            color: root.btConnected.length > 0 ? Style.base0D : Style.fg
        }

        BarText {
            visible: Battery.present
            text: `${Battery.icon} ${Battery.percent}%`
            color: Battery.low ? Style.base08 : Battery.charging ? Style.base0B : Style.fg
        }
    }
}

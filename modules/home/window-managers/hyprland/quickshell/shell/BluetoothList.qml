import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Paired devices first, then named devices found while the list is shown.
Column {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter
        ? adapter.devices.values
            .filter(d => d.paired || d.deviceName !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        : []

    spacing: 2

    Binding {
        when: root.adapter !== null && root.adapter.enabled
        target: root.adapter
        property: "discovering"
        value: root.visible
    }

    PanelText {
        visible: root.devices.length === 0
        text: root.adapter?.enabled ? "Searching…" : "Bluetooth is off"
        opacity: 0.7
        leftPadding: 8
    }

    Repeater {
        model: root.devices.slice(0, 10)

        delegate: ListRow {
            required property BluetoothDevice modelData

            icon: Icons.bluetooth
            text: modelData.name || modelData.address
            highlighted: modelData.connected
            detail: modelData.pairing ? "Pairing…"
                : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                : modelData.state === BluetoothDeviceState.Disconnecting ? "…"
                : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected")
                : modelData.paired ? "Paired" : "Pair"
            onClicked: {
                if (modelData.connected) {
                    modelData.disconnect();
                } else if (modelData.paired) {
                    modelData.connect();
                } else {
                    modelData.trusted = true;
                    modelData.pair();
                }
            }
        }
    }

    ListRow {
        icon: Icons.cog
        text: "Bluetooth settings…"
        onClicked: ShellState.run(Settings.bluetoothSettings)
    }
}

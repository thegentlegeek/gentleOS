pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// NetworkManager state, shaped for the bar and quick settings.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property var wifiNetworks: wifiDevice
        ? wifiDevice.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        : []
    readonly property var activeWifi: wifiNetworks.find(n => n.connected) ?? null

    function strengthIcon(network) {
        return Icons.wifiStrength[Math.min(4, Math.round(network.signalStrength * 4))];
    }

    readonly property string icon: wiredDevice ? Icons.ethernet
        : activeWifi ? strengthIcon(activeWifi)
        : wifiDevice && !wifiEnabled ? Icons.wifiOff
        : Icons.warning

    function setWifi(on) {
        Networking.wifiEnabled = on;
    }
}

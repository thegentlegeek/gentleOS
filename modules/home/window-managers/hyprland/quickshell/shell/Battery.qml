pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Laptop battery (UPower display device), shaped for the bar and quick settings.
Singleton {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool present: dev.isLaptopBattery
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool full: dev.state === UPowerDeviceState.FullyCharged
    readonly property bool low: UPower.onBattery && dev.percentage <= 0.15

    readonly property string icon: charging ? Icons.charging
        : !UPower.onBattery && !full ? Icons.plugged
        : Icons.battery[Math.min(4, Math.floor(dev.percentage * 5))]

    // "3h 20m remaining", "1h 5m until full", "Fully charged", "Plugged in"
    readonly property string status: charging && dev.timeToFull > 0 ? `${hm(dev.timeToFull)} until full`
        : UPower.onBattery && dev.timeToEmpty > 0 ? `${hm(dev.timeToEmpty)} remaining`
        : full ? "Fully charged"
        : !UPower.onBattery ? "Plugged in"
        : ""

    function hm(seconds) {
        const m = Math.round(seconds / 60);
        return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`;
    }
}

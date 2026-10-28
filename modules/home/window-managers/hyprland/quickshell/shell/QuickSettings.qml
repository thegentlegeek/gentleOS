import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

PanelFrame {
    id: root

    // Expanded detail list under the tiles: "", "wifi" or "bluetooth".
    property string section: ""

    readonly property BluetoothAdapter btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnected: btAdapter ? btAdapter.devices.values.filter(d => d.connected) : []

    function toggleSection(s) {
        section = section === s ? "" : s;
    }

    name: "quickSettings"
    panelWidth: 420
    onOpenChanged: if (!open) section = ""

    Grid {
        id: tiles

        readonly property real tileWidth: (width - spacing) / 2

        width: parent.width
        columns: 2
        spacing: 8

        Tile {
            width: tiles.tileWidth
            visible: Net.wifiDevice !== null
            icon: Net.wifiEnabled ? Icons.wifi : Icons.wifiOff
            title: "Wi-Fi"
            subtitle: !Net.wifiEnabled ? "Off" : Net.activeWifi?.name ?? "Not connected"
            active: Net.wifiEnabled
            expandable: true
            expanded: root.section === "wifi"
            onToggled: Net.setWifi(!Net.wifiEnabled)
            onExpandToggled: root.toggleSection("wifi")
        }

        Tile {
            width: tiles.tileWidth
            visible: root.btAdapter !== null
            icon: root.btAdapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
            title: "Bluetooth"
            subtitle: !root.btAdapter?.enabled ? "Off"
                : root.btConnected.length === 1 ? root.btConnected[0].name
                : root.btConnected.length > 1 ? `${root.btConnected.length} devices`
                : "On"
            active: root.btAdapter?.enabled ?? false
            expandable: true
            expanded: root.section === "bluetooth"
            onToggled: root.btAdapter.enabled = !root.btAdapter.enabled
            onExpandToggled: root.toggleSection("bluetooth")
        }

        Tile {
            width: tiles.tileWidth
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            title: "Do not disturb"
            subtitle: Notifs.dnd ? "Critical only" : "Off"
            active: Notifs.dnd
            onToggled: Notifs.dnd = !Notifs.dnd
        }

        Tile {
            width: tiles.tileWidth
            icon: ShellState.caffeine ? Icons.caffeineOn : Icons.caffeineOff
            title: "Keep awake"
            subtitle: ShellState.caffeine ? "Auto-lock paused" : "Off"
            active: ShellState.caffeine
            onToggled: ShellState.caffeine = !ShellState.caffeine
        }
    }

    WifiList {
        width: parent.width
        visible: root.section === "wifi"
    }

    BluetoothList {
        width: parent.width
        visible: root.section === "bluetooth"
    }

    Column {
        width: parent.width
        spacing: 4

        LevelRow {
            visible: Audio.ready
            icon: Audio.icon
            value: Audio.volume
            dimmed: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }

        LevelRow {
            visible: Audio.source?.audio != null
            icon: Audio.micMuted ? Icons.micOff : Icons.mic
            value: Audio.source?.audio?.volume ?? 0
            dimmed: Audio.micMuted
            onMoved: v => Audio.source.audio.volume = v
            onIconClicked: Audio.toggleMic()
        }

        LevelRow {
            visible: Brightness.available
            icon: Brightness.icon
            value: Brightness.level
            onMoved: v => Brightness.set(v)
        }
    }

    // Power profile
    Row {
        id: profiles

        readonly property var options: [
            { profile: PowerProfile.PowerSaver, icon: Icons.profileSaver, label: "Saver" },
            { profile: PowerProfile.Balanced, icon: Icons.profileBalanced, label: "Balanced" },
            { profile: PowerProfile.Performance, icon: Icons.profilePerformance, label: "Performance" },
        ].filter(o => o.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

        width: parent.width
        spacing: 4

        Repeater {
            model: profiles.options

            delegate: Rectangle {
                id: option

                required property var modelData
                readonly property bool selected: PowerProfiles.profile === modelData.profile

                width: (profiles.width - profiles.spacing * (profiles.options.length - 1)) / profiles.options.length
                height: 34
                radius: Style.radius
                color: selected ? Style.base0D : optionArea.containsMouse ? Style.base03 : Style.base02

                PanelText {
                    anchors.centerIn: parent
                    text: `${option.modelData.icon}  ${option.modelData.label}`
                }

                MouseArea {
                    id: optionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerProfiles.profile = option.modelData.profile
                }
            }
        }
    }

    SessionButtons {}
}

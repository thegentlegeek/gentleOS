import Quickshell
import Quickshell.Networking
import QtQuick

// Networks in range. Known or open networks connect on click; others ask for
// a password inline. Scans only while shown.
Column {
    id: root

    // Name of the network whose password field is open.
    property string passwordFor: ""

    spacing: 2

    Binding {
        when: Net.wifiDevice !== null
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: root.visible
    }

    PanelText {
        visible: Net.wifiNetworks.length === 0
        text: Net.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
        opacity: 0.7
        leftPadding: 8
    }

    Repeater {
        model: Net.wifiNetworks.slice(0, 10)

        delegate: Column {
            id: entry

            required property WifiNetwork modelData
            readonly property bool open: modelData.security === WifiSecurityType.Open

            width: root.width

            ListRow {
                icon: Net.strengthIcon(entry.modelData)
                text: entry.modelData.name
                highlighted: entry.modelData.connected
                detail: entry.modelData.stateChanging ? "…"
                    : entry.modelData.connected ? "Connected"
                    : entry.modelData.known ? "Saved"
                    : entry.open ? "Open" : Icons.capsLock
                onClicked: {
                    const n = entry.modelData;
                    if (n.connected)
                        n.disconnect();
                    else if (n.known || entry.open)
                        n.connect();
                    else
                        root.passwordFor = root.passwordFor === n.name ? "" : n.name;
                }
            }

            Rectangle {
                visible: root.passwordFor === entry.modelData.name
                width: parent.width
                height: 34
                radius: Style.radius
                color: Style.base01
                border.width: 1
                border.color: Style.base0D

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Style.fg
                    font.family: Style.fontShell
                    font.pointSize: Style.fontSize
                    clip: true
                    onVisibleChanged: if (visible) forceActiveFocus(); else text = ""
                    onAccepted: {
                        entry.modelData.connectWithPsk(text);
                        root.passwordFor = "";
                    }

                    PanelText {
                        visible: password.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password, then Enter"
                        opacity: 0.5
                    }
                }
            }
        }
    }

    ListRow {
        icon: Icons.cog
        text: "Network settings…"
        onClicked: ShellState.run(Settings.networkSettings)
    }
}

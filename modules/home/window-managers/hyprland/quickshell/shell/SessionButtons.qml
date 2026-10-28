import QtQuick

// Lock / log out / suspend / reboot / shut down. Clicking is the confirmation,
// as with the old rofi power menu.
Row {
    id: root

    readonly property var actions: [
        { icon: Icons.lock, label: "Lock", command: Settings.lock },
        { icon: Icons.logout, label: "Log out", command: Settings.logout },
        { icon: Icons.sleep, label: "Suspend", command: Settings.suspend },
        { icon: Icons.reboot, label: "Reboot", command: Settings.reboot },
        { icon: Icons.power, label: "Shut down", command: Settings.poweroff },
    ]

    width: parent?.width ?? 0
    spacing: 8

    Repeater {
        model: root.actions

        delegate: Rectangle {
            id: button

            required property var modelData
            required property int index

            width: (root.width - root.spacing * (root.actions.length - 1)) / root.actions.length
            height: 64
            radius: Style.radius
            color: area.containsMouse ? (index === root.actions.length - 1 ? Style.base08 : Style.base0D) : Style.base02

            Column {
                anchors.centerIn: parent
                spacing: 4

                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: button.modelData.icon
                    font.pixelSize: 20
                }

                PanelText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: button.modelData.label
                    font.pointSize: Style.fontSizeSmall
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.run(button.modelData.command)
            }
        }
    }
}

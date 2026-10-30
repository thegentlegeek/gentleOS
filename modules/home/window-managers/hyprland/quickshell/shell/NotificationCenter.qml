import Quickshell
import QtQuick

// Everything not yet dismissed, newest first.
PanelFrame {
    id: root

    name: "notifications"
    panelWidth: 440

    Item {
        width: parent.width
        height: 32

        PanelText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            font.pointSize: Style.fontSizeTitle
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Pill {
                color: Notifs.dnd ? Style.highlight : Style.base02
                fg: Notifs.dnd ? Style.highlightText : Style.fg
                padding: 10
                implicitHeight: 30
                text: Notifs.dnd ? Icons.bellOff : Icons.bell
                tooltip: "Do not disturb"
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Pill {
                visible: Notifs.history.length > 0
                color: Style.base02
                padding: 10
                implicitHeight: 30
                text: Icons.clearAll + " Clear"
                onClicked: Notifs.clearAll()
            }
        }
    }

    PanelText {
        visible: Notifs.history.length === 0
        width: parent.width
        height: 64
        horizontalAlignment: Text.AlignHCenter
        text: "No notifications"
        opacity: 0.6
    }

    Flickable {
        visible: Notifs.history.length > 0
        width: parent.width
        height: Math.min(contentHeight, (root.screen?.height ?? 1080) * 0.7)
        contentHeight: list.implicitHeight
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: 6

            Repeater {
                model: ScriptModel {
                    values: Notifs.history
                }

                delegate: NotificationCard {
                    required property var modelData

                    width: list.width
                    notif: modelData
                }
            }
        }
    }
}

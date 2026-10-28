import Quickshell.Hyprland
import QtQuick

// Regular workspaces (special ones have negative ids) as numbered chips:
// focused = accent, shown on another monitor = raised, urgent = red.
Pill {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)

    visible: workspaces.length > 0
    padding: 2

    Repeater {
        model: root.workspaces

        delegate: Rectangle {
            id: chip

            required property HyprlandWorkspace modelData

            width: Math.max(28, label.implicitWidth + 16)
            height: 20
            radius: Style.radius - 2
            color: modelData.focused ? Style.base0D
                : modelData.urgent ? Style.base08
                : modelData.active ? Style.base03
                : area.containsMouse ? Style.base03
                : "transparent"

            BarText {
                id: label
                anchors.centerIn: parent
                text: chip.modelData.name
                font.pixelSize: Style.fontSizeBar - 1
                font.bold: chip.modelData.focused
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.modelData.activate()
            }
        }
    }
}

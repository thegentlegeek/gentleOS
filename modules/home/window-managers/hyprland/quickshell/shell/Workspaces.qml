import Quickshell.Hyprland
import QtQuick

// All regular workspaces (special ones have negative ids), sorted by number.
Pill {
    padding: 8

    Repeater {
        model: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)

        delegate: BarText {
            id: ws

            required property HyprlandWorkspace modelData

            leftPadding: 6
            rightPadding: 6
            text: modelData.name + " " + (modelData.urgent ? Icons.wsUrgent
                : modelData.active ? Icons.wsActive
                : Icons.wsDefault)
            color: modelData.focused ? Style.base0A : Style.base07

            MouseArea {
                anchors.fill: parent
                onClicked: ws.modelData.activate()
            }
        }
    }
}

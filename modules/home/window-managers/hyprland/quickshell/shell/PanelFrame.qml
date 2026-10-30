import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// A panel under the bar on the focused monitor. Opened through ShellState;
// closed by Esc or by clicking anywhere outside it (Hyprland focus grab).
PanelWindow {
    id: root

    // Its ShellState.openPanel value.
    required property string name
    default property alias content: body.data
    property int panelWidth: 400
    property bool alignRight: true

    readonly property bool open: ShellState.openPanel === name

    visible: open
    screen: ShellState.focusedScreen
    anchors.top: true
    anchors.right: alignRight
    margins.top: 8
    margins.right: 16
    // Don't reserve space; sit below the bar's exclusive zone.
    exclusiveZone: 0
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + 32
    color: "transparent"

    WlrLayershell.namespace: "gentle-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: ShellState.close(root.name)
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: Style.panelBg
        border.width: 2
        border.color: Style.base0D
        focus: true
        Keys.onEscapePressed: ShellState.close(root.name)

        Column {
            id: body
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 12
        }
    }
}

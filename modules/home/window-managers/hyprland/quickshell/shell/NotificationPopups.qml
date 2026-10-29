import Quickshell
import Quickshell.Wayland
import QtQuick

// Popups at the top center of the focused monitor, newest on top (where dunst
// put them). Hidden while the notification center shows the same ones.
PanelWindow {
    visible: Notifs.popups.length > 0 && ShellState.openPanel !== "notifications"
    screen: ShellState.focusedScreen
    anchors.top: true
    margins.top: 8
    exclusiveZone: 0
    implicitWidth: 420
    implicitHeight: column.implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "gentle-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: column
        width: parent.width
        spacing: 5

        Repeater {
            // ScriptModel keeps existing delegates (and their timers) when a
            // new popup is prepended.
            model: ScriptModel {
                values: Notifs.popups
            }

            delegate: NotificationCard {
                required property var modelData

                width: column.width
                notif: modelData
                popup: true
            }
        }
    }
}

import Quickshell
import QtQuick

// Hover tooltip below `target`, created only while shown.
Item {
    id: root

    required property Item target
    property string text: ""
    property bool hovered: false

    Timer {
        id: delay
        interval: 500
        running: root.hovered && root.text !== ""
    }

    LazyLoader {
        active: root.hovered && root.text !== "" && !delay.running

        PopupWindow {
            visible: true
            anchor.item: root.target
            anchor.edges: Edges.Bottom
            anchor.gravity: Edges.Bottom
            anchor.margins.top: 8
            implicitWidth: label.implicitWidth + 24
            implicitHeight: label.implicitHeight + 16
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Style.radius
                color: Style.alpha(Style.base00, 0.9)
                border.width: 2
                border.color: Style.fg

                PanelText {
                    id: label
                    anchors.centerIn: parent
                    text: root.text
                    elide: Text.ElideNone
                }
            }
        }
    }
}

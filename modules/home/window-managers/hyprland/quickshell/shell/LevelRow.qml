import QtQuick

// Icon button + slider + percentage, for volume and brightness.
Item {
    id: root

    property string icon
    property real value: 0
    property bool dimmed: false

    signal moved(real value)
    signal iconClicked

    width: parent?.width ?? 0
    implicitHeight: 32

    Rectangle {
        id: iconButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: Style.radius
        color: iconArea.containsMouse ? Style.base02 : "transparent"

        BarText {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: 18
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        id: track
        anchors.left: iconButton.right
        anchors.leftMargin: 8
        anchors.right: percent.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Style.base02

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: 4
                color: root.dimmed ? Style.base03 : Style.base0D
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: m => root.moved(Math.max(0, Math.min(1, m.x / width)))
            onPositionChanged: m => {
                if (pressed)
                    root.moved(Math.max(0, Math.min(1, m.x / width)));
            }
            onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    PanelText {
        id: percent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
    }
}

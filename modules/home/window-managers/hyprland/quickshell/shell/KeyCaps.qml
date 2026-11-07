import QtQuick

// Keys drawn as keyboard caps with a raised bottom edge ("Super" "E").
Row {
    id: root

    property var keys: []
    property real pointSize: Style.fontSizeSmall

    spacing: 4

    Repeater {
        model: root.keys

        // The darker cap behind shows as the bottom edge.
        Rectangle {
            id: cap

            required property string modelData

            implicitWidth: Math.max(label.implicitWidth + 12, implicitHeight)
            implicitHeight: label.implicitHeight + 6
            radius: 5
            color: Style.base04

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: 2
                radius: parent.radius
                color: Style.base03
            }

            PanelText {
                id: label
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: cap.modelData
                color: Style.base06
                font.pointSize: root.pointSize
            }
        }
    }
}

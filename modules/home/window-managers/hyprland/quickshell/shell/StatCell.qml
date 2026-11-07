import QtQuick

// One system reading in quick settings: icon + value over a label, with a
// usage bar. `warn` turns it yellow, `critical` red.
Rectangle {
    id: root

    property string icon
    property string value
    property string label
    property real fraction: -1
    property bool warn: false
    property bool critical: false

    readonly property color accent: critical ? Style.base08 : warn ? Style.base0A : Style.base0D

    implicitHeight: 64
    radius: Style.radius
    color: Style.base01

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 4

        PanelText {
            width: parent.width
            text: `${root.icon}  ${root.value}`
            color: root.warn || root.critical ? root.accent : Style.fg
            font.bold: true
        }

        PanelText {
            width: parent.width
            text: root.label
            color: Style.muted
            font.pointSize: Style.fontSizeSmall
        }

        Rectangle {
            visible: root.fraction >= 0
            width: parent.width
            height: 3
            radius: 2
            color: Style.base02

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.fraction))
                height: parent.height
                radius: 2
                color: root.accent
            }
        }
    }
}

import QtQuick

// One rounded module on the bar: `text` and/or child items, clicks, scrolling
// and a tooltip.
Rectangle {
    id: root

    default property alias content: row.data
    property string text: ""
    property color fg: Style.base07
    property bool italic: false
    property string tooltip: ""
    property int padding: 16

    signal clicked(var mouse)
    // +1 per scroll notch up, -1 down.
    signal scrolled(int step)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 24
    radius: Style.radius
    color: Style.pillBg

    // Below the row, so child items with their own MouseArea get clicks first.
    MouseArea {
        id: mouse

        property real wheelAccum: 0

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        // Touchpads send many small deltas; emit once per notch (120).
        onWheel: w => {
            wheelAccum += w.angleDelta.y;
            while (Math.abs(wheelAccum) >= 120) {
                const step = wheelAccum > 0 ? 1 : -1;
                wheelAccum -= step * 120;
                root.scrolled(step);
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        BarText {
            visible: root.text !== ""
            text: root.text
            color: root.fg
            font.italic: root.italic
        }
    }

    Tooltip {
        target: root
        text: root.tooltip
        hovered: mouse.containsMouse
    }
}

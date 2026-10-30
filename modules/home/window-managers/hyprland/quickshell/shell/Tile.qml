import QtQuick

// Quick settings toggle; the chevron (if `expandable`) opens a detail list.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool expandable: false
    property bool expanded: false

    signal toggled
    signal expandToggled

    // Text follows the fill (see Style.highlightText).
    readonly property color textColor: active ? Style.highlightText : Style.fg

    implicitHeight: 56
    radius: Style.radius
    color: active ? Style.highlight : Style.base02
    opacity: mainArea.pressed ? 0.8 : 1

    MouseArea {
        id: mainArea
        anchors.fill: parent
        anchors.rightMargin: root.expandable ? 36 : 0
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: root.expandable ? 40 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BarText {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.textColor
            font.pixelSize: 20
        }

        Column {
            width: parent.width - iconText.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter

            PanelText {
                width: parent.width
                text: root.title
                color: root.textColor
                font.bold: true
            }

            PanelText {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                color: root.textColor
                font.pointSize: Style.fontSizeSmall
                opacity: 0.8
            }
        }
    }

    Rectangle {
        visible: root.expandable
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 36
        radius: Style.radius
        color: chevronArea.containsMouse ? Style.alpha(Style.base00, 0.2) : "transparent"

        BarText {
            anchors.centerIn: parent
            text: Icons.chevron
            color: root.textColor
            rotation: root.expanded ? 90 : 0
        }

        MouseArea {
            id: chevronArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandToggled()
        }
    }
}

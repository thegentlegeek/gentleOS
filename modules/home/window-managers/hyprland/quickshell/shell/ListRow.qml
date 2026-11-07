import QtQuick

// A clickable row in a panel list (wifi networks, bluetooth devices...).
Rectangle {
    id: root

    property string icon
    property string text
    property string detail
    property bool highlighted: false

    signal clicked

    width: parent?.width ?? 0
    implicitHeight: 34
    radius: Style.radius
    color: area.containsMouse ? Style.base02 : "transparent"

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    BarText {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        text: root.icon
        color: root.highlighted ? Style.base0D : Style.fg
        font.pixelSize: 16
    }

    PanelText {
        anchors.left: iconText.right
        anchors.leftMargin: 8
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.highlighted ? Style.base0D : Style.fg
        font.bold: root.highlighted
    }

    PanelText {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        font.pointSize: Style.fontSizeSmall
        opacity: 0.7
    }
}

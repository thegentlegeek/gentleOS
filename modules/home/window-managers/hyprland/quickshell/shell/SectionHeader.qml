import QtQuick

// Small uppercase label above a group in a panel, with optional detail text
// (e.g. the audio device) on the right.
Item {
    id: root

    property string title
    property string detail

    width: parent?.width ?? 0
    implicitHeight: 18

    PanelText {
        id: titleText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Style.muted
        font.pointSize: Style.fontSizeSmall
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    PanelText {
        anchors.left: titleText.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.detail
        color: Style.muted
        font.pointSize: Style.fontSizeSmall
    }
}

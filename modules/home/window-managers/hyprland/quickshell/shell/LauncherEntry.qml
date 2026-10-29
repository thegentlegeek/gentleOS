import QtQuick

// One of LauncherState.rows: a section header, or a LauncherRow.
Item {
    id: root

    required property var row
    // Headers at the top of a list or column get less space above them.
    property bool first: false
    property bool selected: false

    signal pointed
    signal activated(bool alt)

    readonly property bool header: row.header ?? false

    implicitHeight: header ? (first ? 24 : 34) : rowItem.implicitHeight

    PanelText {
        visible: root.header
        x: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        text: root.row.title ?? ""
        color: Style.subtle
        font.pointSize: Style.fontSizeSmall - 1
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    LauncherRow {
        id: rowItem
        visible: !root.header
        width: parent.width
        item: root.row
        selected: root.selected
        onPointed: root.pointed()
        onActivated: alt => root.activated(alt)
    }
}

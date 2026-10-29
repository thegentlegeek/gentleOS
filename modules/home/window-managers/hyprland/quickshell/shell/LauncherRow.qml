import Quickshell.Widgets
import QtQuick

// One launcher result (see LauncherState for the item fields). Two lines
// (title, subtitle) by default; one line with a small kind label if compact.
Rectangle {
    id: root

    required property var item
    property bool selected: false

    signal activated(bool alt)
    signal pointed

    readonly property bool compact: item.compact ?? false

    implicitHeight: compact ? 44 : 52
    radius: 8
    color: selected ? Style.base02 : "transparent"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Not onEntered: rows scrolling under a still pointer would steal the
        // keyboard selection.
        onPositionChanged: root.pointed()
        onClicked: mouse => root.activated(mouse.modifiers & Qt.ShiftModifier)
    }

    Rectangle {
        id: tile
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: root.compact ? 30 : 34
        height: width
        radius: 8
        color: root.selected ? Style.base00 : Style.base02

        IconImage {
            id: image
            anchors.centerIn: parent
            implicitSize: root.compact ? 20 : 24
            source: root.item.icon ?? ""
            visible: source != "" && status === Image.Ready
        }

        BarText {
            anchors.centerIn: parent
            visible: !image.visible
            text: root.item.glyph ?? ""
            color: root.selected ? Style.accent : Style.base06
            font.pixelSize: root.compact ? 15 : 18
        }
    }

    Item {
        id: texts
        anchors.left: tile.right
        anchors.leftMargin: 12
        anchors.right: trailing.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: root.compact ? title.implicitHeight : title.implicitHeight + 2 + subtitle.implicitHeight

        PanelText {
            id: title
            width: root.compact ? Math.min(implicitWidth, parent.width - label.implicitWidth - 10) : parent.width
            textFormat: root.item.titleHtml ? Text.StyledText : Text.PlainText
            text: root.item.titleHtml || (root.item.title ?? "")
            font.pointSize: root.compact ? Style.fontSize : Style.fontSize + 1
            font.weight: root.selected ? Font.Medium : Font.Normal
        }

        // Compact rows: what kind of item this is, after the title.
        PanelText {
            id: label
            visible: root.compact && text !== ""
            anchors.left: title.right
            anchors.leftMargin: 10
            anchors.baseline: title.baseline
            text: root.item.label ?? ""
            color: Style.subtle
            font.pointSize: Style.fontSizeSmall - 1
        }

        PanelText {
            id: subtitle
            visible: !root.compact
            anchors.top: title.bottom
            anchors.topMargin: 2
            width: parent.width
            textFormat: root.item.subtitleHtml ? Text.StyledText : Text.PlainText
            text: root.item.subtitleHtml || (root.item.subtitle ?? "")
            color: Style.subtle
            font.pointSize: Style.fontSizeSmall
        }
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        PanelText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: root.item.hint ?? ""
            color: Style.subtle
            font.pointSize: Style.fontSizeSmall
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: (root.item.badge ?? "") !== ""
            implicitWidth: badge.implicitWidth + 16
            implicitHeight: badge.implicitHeight + 6
            radius: 6
            color: root.selected ? Style.base03 : Style.base02

            PanelText {
                id: badge
                anchors.centerIn: parent
                text: root.item.badge ?? ""
                color: Style.base06
                font.pointSize: Style.fontSizeSmall
            }
        }

        KeyCaps {
            anchors.verticalCenter: parent.verticalCenter
            keys: root.item.keys ?? []
        }

        // Enter hint on the selection, unless the item has its own keys.
        KeyCaps {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selected && !root.item.disabled && (root.item.keys ?? []).length === 0
            keys: ["↵"]
        }
    }
}

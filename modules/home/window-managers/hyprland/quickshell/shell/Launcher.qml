import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// The launcher: a command palette in the upper third of the focused monitor.
// SUPER+A (hyprland.lua) toggles it; typing a mode prefix (LauncherState.modes)
// switches mode. Esc or a click outside closes it.
PanelWindow {
    id: root

    visible: LauncherState.open
    screen: ShellState.focusedScreen
    anchors.top: true
    margins.top: Math.round((screen?.height ?? 1080) * 0.15)
    exclusiveZone: 0
    // Sized for the widest and tallest mode, with the card drawn at the top and
    // only the card taking input: resizing the surface as results change made
    // Hyprland drop keystrokes typed during the resize.
    implicitWidth: 1000
    implicitHeight: 700
    color: "transparent"
    mask: Region {
        item: card
    }

    WlrLayershell.namespace: "gentle-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: LauncherState.close()
    }

    onVisibleChanged: {
        if (!visible)
            return;
        input.text = LauncherState.query;
        input.forceActiveFocus();
    }

    // LauncherState changes the query too (mode prefixes, show()).
    Connections {
        target: LauncherState

        function onQueryChanged() {
            if (input.text !== LauncherState.query)
                input.text = LauncherState.query;
        }
    }

    function current() {
        return LauncherState.rows[list.currentIndex] ?? null;
    }

    // Next non-header row from `from` in direction `step`, or `from`.
    function nextRow(from, step) {
        const rows = LauncherState.rows;
        for (let i = from + step; i >= 0 && i < rows.length; i += step) {
            if (!rows[i].header)
                return i;
        }
        return from;
    }

    function move(step) {
        let i = list.currentIndex;
        for (let n = Math.abs(step); n > 0; n--)
            i = nextRow(i, Math.sign(step));
        list.currentIndex = i;
        list.positionViewAtIndex(i, ListView.Contain);
    }

    function key(event) {
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Escape:
            if (LauncherState.actionsOf)
                LauncherState.actionsOf = null;
            else
                LauncherState.close();
            break;
        case Qt.Key_Down:
            move(1);
            break;
        case Qt.Key_Up:
            move(-1);
            break;
        case Qt.Key_PageDown:
            move(5);
            break;
        case Qt.Key_PageUp:
            move(-5);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            LauncherState.activate(current(), shift);
            break;
        case Qt.Key_Tab:
            LauncherState.showActions(current());
            break;
        case Qt.Key_Backspace:
            if (input.text !== "" || event.isAutoRepeat) {
                event.accepted = input.text === "";
                return;
            }
            LauncherState.back();
            break;
        case Qt.Key_N:
        case Qt.Key_J:
            if (!ctrl) {
                event.accepted = false;
                return;
            }
            move(1);
            break;
        case Qt.Key_P:
        case Qt.Key_K:
            if (!ctrl) {
                event.accepted = false;
                return;
            }
            move(-1);
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Item {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        width: LauncherState.width
        height: content.implicitHeight + 4

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Style.panelBg
        }

        Column {
            id: content

            x: 2
            y: 2
            width: parent.width - 4

            // Search field, with the active mode as a chip in front of it.
            Item {
                width: parent.width
                height: 60

                Rectangle {
                    id: chip
                    visible: LauncherState.currentMode !== null
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: chipRow.implicitWidth + 20
                    implicitHeight: 28
                    radius: 6
                    color: Style.accent

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: LauncherState.currentMode?.glyph ?? ""
                            color: Style.base00
                            font.pixelSize: 15
                        }

                        PanelText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: LauncherState.currentMode?.title ?? ""
                            color: Style.base00
                            font.bold: true
                        }
                    }
                }

                BarText {
                    id: searchGlyph
                    visible: !chip.visible
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.search
                    color: Style.subtle
                    font.pixelSize: 20
                }

                TextInput {
                    id: input
                    anchors.left: chip.visible ? chip.right : searchGlyph.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: Style.base07
                    selectionColor: Style.base03
                    selectedTextColor: Style.base07
                    font.family: Style.fontShell
                    font.pointSize: Style.fontSize * 1.5
                    clip: true
                    focus: true

                    onTextEdited: {
                        LauncherState.input(text);
                        if (text !== LauncherState.query)
                            text = LauncherState.query;
                    }
                    Keys.onPressed: event => root.key(event)

                    PanelText {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: LauncherState.actionsOf ? "Actions" : LauncherState.currentMode?.placeholder ?? "Search apps, windows, keybinds…"
                        color: Style.subtle
                        font.pointSize: input.font.pointSize
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Style.base02
            }

            ListView {
                id: list

                width: parent.width
                height: Math.min(contentHeight + topMargin + bottomMargin, 540)
                visible: count > 0
                topMargin: 6
                bottomMargin: 8
                leftMargin: 8
                rightMargin: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: LauncherState.rows
                onModelChanged: {
                    currentIndex = root.nextRow(-1, 1);
                    positionViewAtBeginning();
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index

                    width: list.width - list.leftMargin - list.rightMargin
                    height: modelData.header ? (index === 0 ? 24 : 34) : rowItem.implicitHeight

                    PanelText {
                        visible: row.modelData.header ?? false
                        x: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        text: row.modelData.title ?? ""
                        color: Style.subtle
                        font.pointSize: Style.fontSizeSmall - 1
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }

                    LauncherRow {
                        id: rowItem
                        visible: !(row.modelData.header ?? false)
                        width: parent.width
                        item: row.modelData
                        selected: list.currentIndex === row.index
                        onPointed: list.currentIndex = row.index
                        onActivated: alt => LauncherState.activate(row.modelData, alt)
                    }
                }
            }

            // Mode prefixes; the active one is lit.
            Rectangle {
                width: parent.width
                height: 40
                color: Style.alpha(Style.base01, 0.9)
                bottomLeftRadius: Style.radius - 2
                bottomRightRadius: Style.radius - 2

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Style.base02
                }

                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Repeater {
                        model: LauncherState.modes

                        Row {
                            id: modeHint

                            required property var modelData
                            readonly property bool active: LauncherState.mode === modelData.mode

                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.max(prefix.implicitWidth + 8, 20)
                                implicitHeight: prefix.implicitHeight + 2
                                radius: 4
                                color: modeHint.active ? Style.accent : Style.base03

                                PanelText {
                                    id: prefix
                                    anchors.centerIn: parent
                                    text: modeHint.modelData.prefix
                                    color: modeHint.active ? Style.base00 : Style.base06
                                    font.bold: true
                                    font.pointSize: Style.fontSizeSmall
                                }
                            }

                            PanelText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeHint.modelData.label
                                color: modeHint.active ? Style.base07 : Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }
                        }
                    }
                }
            }
        }

        // Border on top of the content's square-cornered backgrounds.
        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: "transparent"
            border.width: 2
            border.color: Style.base0E
        }
    }
}

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// The launcher: a command palette in the upper third of the focused monitor.
// SUPER+A (hyprland.lua) toggles it; typing a mode prefix (LauncherState.modes)
// switches mode. Esc or a click outside closes it.
PanelWindow {
    id: root

    // Index of the selected row in LauncherState.rows.
    property int selected: -1

    readonly property var mode: LauncherState.currentMode
    readonly property bool split: mode?.split ?? false

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

    Connections {
        target: LauncherState

        // LauncherState changes the query too (mode prefixes, show()).
        function onQueryChanged() {
            if (input.text !== LauncherState.query)
                input.text = LauncherState.query;
        }

        function onRowsChanged() {
            const rows = LauncherState.rows;
            const first = rows.findIndex(r => !r.header && !r.passive);
            root.selected = first >= 0 ? first : root.nextRow(-1, 1);
            list.positionViewAtBeginning();
            columns.contentY = 0;
        }
    }

    function plural(n, word) {
        return `${n} ${word}${n === 1 ? "" : "s"}`;
    }

    function current() {
        return LauncherState.rows[selected] ?? null;
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
        let i = selected;
        for (let n = Math.abs(step); n > 0; n--)
            i = nextRow(i, Math.sign(step));
        selected = i;
        list.positionViewAtIndex(i, ListView.Contain);
    }

    // Scroll the cheat sheet so `item` (one of its entries) is visible.
    function reveal(item) {
        const y = item.mapToItem(columnsRow, 0, 0).y + columnsRow.y;
        if (y < columns.contentY + 6)
            columns.contentY = Math.max(0, y - 30);
        else if (y + item.height > columns.contentY + columns.height - 6)
            columns.contentY = y + item.height - columns.height + 8;
    }

    function key(event) {
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;

        // Per-item keys, like Ctrl+D to delete a clipboard entry.
        const letter = event.key >= Qt.Key_A && event.key <= Qt.Key_Z ? String.fromCharCode(event.key).toLowerCase() : "";
        const action = ctrl && letter ? current()?.keyActions?.["ctrl+" + letter] : null;
        if (action) {
            action();
            event.accepted = true;
            return;
        }

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
            LauncherState.tab(current());
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
                    visible: root.mode !== null
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
                            text: root.mode?.glyph ?? ""
                            color: Style.base00
                            font.pixelSize: 15
                        }

                        PanelText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.mode?.title ?? ""
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
                    anchors.right: tabs.left
                    anchors.rightMargin: 12
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
                        width: parent.width
                        text: LauncherState.actionsOf ? "Actions" : root.mode?.placeholder ?? "Search apps, windows, keybinds…"
                        color: Style.subtle
                        font.pointSize: input.font.pointSize
                    }
                }

                // Keybinds mode: the categories Tab cycles through.
                Row {
                    id: tabs
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: LauncherState.mode === "keybinds" ? [""].concat(LauncherBinds.categories) : []

                        Rectangle {
                            id: tab

                            required property string modelData
                            readonly property bool active: LauncherState.bindCategory === modelData

                            implicitWidth: tabText.implicitWidth + 16
                            implicitHeight: tabText.implicitHeight + 8
                            radius: 6
                            color: active ? Style.base02 : "transparent"

                            PanelText {
                                id: tabText
                                anchors.centerIn: parent
                                text: tab.modelData || "All"
                                color: tab.active ? Style.base07 : Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LauncherState.bindCategory = tab.modelData
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Style.base02
            }

            // Results: a list, a list beside a preview (clipboard, windows), or
            // the cheat sheet's two columns (keybinds).
            Item {
                width: parent.width
                height: LauncherState.mode === "keybinds" ? columns.height : root.split ? 420 : list.height

                ListView {
                    id: list

                    visible: LauncherState.mode !== "keybinds"
                    width: root.split ? 400 : parent.width
                    height: root.split ? parent.height : count > 0 ? Math.min(contentHeight + topMargin + bottomMargin, 540) : 0
                    topMargin: 6
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: LauncherState.mode === "keybinds" ? [] : LauncherState.rows

                    delegate: LauncherEntry {
                        required property var modelData
                        required property int index

                        width: list.width - list.leftMargin - list.rightMargin
                        row: modelData
                        first: index === 0
                        selected: root.selected === index
                        onPointed: root.selected = index
                        onActivated: alt => LauncherState.activate(modelData, alt)
                    }
                }

                Rectangle {
                    visible: root.split
                    x: 400
                    width: 1
                    height: parent.height
                    color: Style.base02
                }

                Loader {
                    x: 401
                    width: parent.width - 401
                    height: parent.height
                    active: root.split
                    sourceComponent: LauncherState.mode === "clipboard" ? clipboardPreview : null
                }

                Flickable {
                    id: columns

                    readonly property var rows: LauncherState.mode === "keybinds" ? LauncherState.rows : []
                    // Split at the header nearest the middle.
                    readonly property int splitAt: {
                        let best = rows.length;
                        for (let i = 1; i < rows.length; i++) {
                            if (rows[i].header && Math.abs(i - rows.length / 2) < Math.abs(best - rows.length / 2))
                                best = i;
                        }
                        return best;
                    }

                    visible: LauncherState.mode === "keybinds"
                    width: parent.width
                    height: visible ? Math.min(contentHeight, 540) : 0
                    contentHeight: columnsRow.implicitHeight + 14
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: columnsRow
                        x: 8
                        y: 6
                        width: parent.width - 16
                        spacing: 8

                        Repeater {
                            model: [[0, columns.splitAt], [columns.splitAt, columns.rows.length]]

                            Column {
                                id: column

                                required property var modelData

                                width: (columnsRow.width - columnsRow.spacing) / 2

                                Repeater {
                                    model: Array.from({ length: column.modelData[1] - column.modelData[0] }, (_, i) => column.modelData[0] + i)

                                    LauncherEntry {
                                        required property int modelData

                                        width: column.width
                                        row: columns.rows[modelData]
                                        first: modelData === column.modelData[0]
                                        selected: root.selected === modelData
                                        onSelectedChanged: if (selected) root.reveal(this)
                                        onPointed: root.selected = modelData
                                        onActivated: alt => LauncherState.activate(row, alt)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer: the mode's key hints, or the mode prefixes with the active one lit.
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
                    spacing: 18
                    visible: root.mode?.hints !== undefined

                    Repeater {
                        model: root.mode?.hints ?? []

                        Row {
                            id: hint

                            required property var modelData

                            spacing: 6

                            KeyCaps {
                                anchors.verticalCenter: parent.verticalCenter
                                keys: hint.modelData[0]
                            }

                            PanelText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: hint.modelData[1]
                                color: Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }
                        }
                    }
                }

                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    visible: root.mode?.hints === undefined

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

    // Clipboard mode: the selected entry in full, and what can be done with it.
    Component {
        id: clipboardPreview

        Item {
            id: preview

            readonly property var entry: root.current()?.entry ?? null
            readonly property bool loaded: entry !== null && LauncherClipboard.previewId === entry.id
            readonly property string fullText: loaded ? LauncherClipboard.previewText : entry?.text ?? ""

            onEntryChanged: LauncherClipboard.preview(entry)
            Component.onCompleted: LauncherClipboard.preview(entry)

            PanelText {
                id: meta
                x: 18
                y: 16
                width: parent.width - 36
                text: !preview.entry ? ""
                    : preview.entry.image ? `Image · ${preview.entry.image.width}×${preview.entry.image.height} · ${preview.entry.image.size}`
                    : `Text · ${root.plural(preview.fullText.split("\n").length, "line")} · ${root.plural(preview.fullText.length, "char")}`
                color: Style.subtle
                font.pointSize: Style.fontSizeSmall
            }

            Rectangle {
                x: 18
                anchors.top: meta.bottom
                anchors.topMargin: 12
                anchors.bottom: actions.top
                anchors.bottomMargin: 14
                width: parent.width - 36
                radius: 8
                color: Style.alpha(Style.base01, 0.9)
                border.width: 1
                border.color: Style.base02
                clip: true

                Text {
                    visible: !(preview.entry?.image)
                    anchors.fill: parent
                    anchors.margins: 14
                    text: preview.fullText
                    color: Style.base06
                    font.family: Style.fontMono
                    font.pointSize: Style.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Image {
                    visible: preview.entry?.image ?? false
                    anchors.fill: parent
                    anchors.margins: 10
                    source: preview.entry ? (LauncherClipboard.thumbs[preview.entry.id] ?? "") : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }

            Row {
                id: actions
                x: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 16

                Repeater {
                    model: [
                        [["↵"], "Copy"],
                        [["Ctrl", "P"], LauncherState.isPinned(preview.entry?.id ?? "") ? "Unpin" : "Pin"],
                        [["Ctrl", "D"], "Delete"]
                    ]

                    Row {
                        id: action

                        required property var modelData

                        spacing: 6

                        KeyCaps {
                            anchors.verticalCenter: parent.verticalCenter
                            keys: action.modelData[0]
                        }

                        PanelText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: action.modelData[1]
                            color: Style.subtle
                            font.pointSize: Style.fontSizeSmall
                        }
                    }
                }
            }
        }
    }
}

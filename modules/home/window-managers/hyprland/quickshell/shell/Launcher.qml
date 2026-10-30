import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// The launcher: a command palette in the upper third of the focused monitor.
// SUPER+Space (hyprland.lua) toggles it; typing a mode prefix (LauncherState.modes)
// switches mode. Esc or a click outside closes it.
PanelWindow {
    id: root

    // Index of the selected row in LauncherState.rows.
    property int selected: -1
    // Selection survives rows refreshing under the same query (thumbnails
    // arriving, a pin, a confirmation) but resets when the query changes.
    property var selectedRow: null
    property string rowsFor: ""

    onSelectedChanged: selectedRow = LauncherState.rows[selected] ?? null

    readonly property var mode: LauncherState.currentMode
    // Footer key hints: the actions list's, else the mode's (none: mode prefixes).
    readonly property var hints: LauncherState.actionsOf ? [[["↵"], "open"], [["Esc"], "back"]] : mode?.hints
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
        lastPoint = null;
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
            const state = LauncherState.mode + "\n" + LauncherState.query;
            const same = state === root.rowsFor;
            root.rowsFor = state;
            const key = r => r ? r.key ?? r.entry?.id ?? r.toplevel ?? r.title : undefined;
            const kept = same && root.selectedRow ? rows.findIndex(r => !r.header && key(r) === key(root.selectedRow)) : -1;
            if (kept >= 0) {
                root.selected = kept;
                root.selectedRow = rows[kept];
                return;
            }
            const first = rows.findIndex(r => !r.header && !r.passive);
            // Calc mode: nothing selected, so Enter copies the result.
            root.selected = first >= 0 ? first : LauncherState.mode === "calc" ? -1 : root.nextRow(-1, 1);
            list.positionViewAtBeginning();
            emojiView.positionViewAtBeginning();
            columns.contentY = 0;
        }
    }

    // Where the pointer was last seen over a row, so only real movement
    // selects: opening under a resting pointer must not move the selection.
    property var lastPoint: null

    function point(p, index) {
        const moved = lastPoint && Math.abs(p.x - lastPoint.x) + Math.abs(p.y - lastPoint.y) > 2;
        lastPoint = p;
        if (moved)
            selected = index;
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

        // Mode keys.
        const m = LauncherState.mode;
        if (m === "emoji" && !ctrl && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                emojiView.step(event.key === Qt.Key_Down ? 1 : -1);
            } else {
                selected = Math.max(0, Math.min(LauncherState.rows.length - 1, selected + (event.key === Qt.Key_Right ? 1 : -1)));
                emojiView.positionViewAtIndex(emojiView.lineOf(selected), ListView.Contain);
            }
            event.accepted = true;
            return;
        }
        if (m === "run" && ctrl && letter === "t") {
            LauncherRun.inTerminal = !LauncherRun.inTerminal;
            event.accepted = true;
            return;
        }
        if (m === "power" && !ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
            selected = Math.min(event.key - Qt.Key_1, LauncherState.rows.length - 1);
            event.accepted = true;
            return;
        }
        // Shift+1…0 arrives as the shifted symbol (US layout).
        const workspace = [Qt.Key_Exclam, Qt.Key_At, Qt.Key_NumberSign, Qt.Key_Dollar, Qt.Key_Percent,
            Qt.Key_AsciiCircum, Qt.Key_Ampersand, Qt.Key_Asterisk, Qt.Key_ParenLeft, Qt.Key_ParenRight].indexOf(event.key) + 1;
        if (m === "windows" && workspace > 0 && current()?.toplevel) {
            LauncherState.close();
            LauncherWindows.moveTo(current().toplevel, workspace);
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            if (LauncherState.actionsOf)
                LauncherState.actionsOf = null;
            else if (LauncherPower.confirming !== "")
                LauncherPower.confirming = "";
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
                    anchors.right: extras.left
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

                // Mode extras on the right: keybind categories, where run mode
                // runs commands, power mode's uptime.
                Row {
                    id: extras
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    PanelText {
                        visible: LauncherState.mode === "power"
                        anchors.verticalCenter: parent.verticalCenter
                        text: LauncherPower.uptimeText
                        color: Style.subtle
                        font.pointSize: Style.fontSizeSmall
                    }

                    Rectangle {
                        visible: LauncherState.mode === "run"
                        implicitWidth: runToggle.implicitWidth + 6
                        implicitHeight: runToggle.implicitHeight + 6
                        radius: 7
                        color: Style.base01

                        Row {
                            id: runToggle
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: [["kitty", true], ["background", false]]

                                Rectangle {
                                    id: runOption

                                    required property var modelData
                                    readonly property bool active: LauncherRun.inTerminal === modelData[1]

                                    implicitWidth: runText.implicitWidth + 18
                                    implicitHeight: runText.implicitHeight + 8
                                    radius: 5
                                    color: active ? Style.base03 : "transparent"

                                    PanelText {
                                        id: runText
                                        anchors.centerIn: parent
                                        text: runOption.modelData[0]
                                        color: runOption.active ? Style.base07 : Style.subtle
                                        font.pointSize: Style.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: LauncherRun.inTerminal = runOption.modelData[1]
                                    }
                                }
                            }
                        }
                    }

                    // [value, label] pairs; Tab cycles them (LauncherState.tab).
                    Repeater {
                        model: LauncherState.mode === "keybinds" ? [["", "All"]].concat(LauncherBinds.categories.map(c => [c, c]))
                            : LauncherState.mode === "emoji" ? LauncherEmoji.tabs : []

                        Rectangle {
                            id: tab

                            required property var modelData
                            readonly property bool active: (LauncherState.mode === "emoji" ? LauncherState.emojiTab : LauncherState.bindCategory) === modelData[0]

                            implicitWidth: tabText.implicitWidth + 16
                            implicitHeight: tabText.implicitHeight + 8
                            radius: 6
                            color: active ? Style.base02 : "transparent"

                            PanelText {
                                id: tabText
                                anchors.centerIn: parent
                                text: tab.modelData[1]
                                color: tab.active ? Style.base07 : Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (LauncherState.mode === "emoji")
                                        LauncherState.emojiTab = tab.modelData[0];
                                    else
                                        LauncherState.bindCategory = tab.modelData[0];
                                }
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
                height: LauncherState.mode === "keybinds" ? columns.height
                    : LauncherState.mode === "power" ? powerView.implicitHeight
                    : LauncherState.mode === "emoji" ? emojiView.height
                    : root.split ? 420 : list.height

                ListView {
                    id: list

                    readonly property bool used: !["keybinds", "power", "emoji"].includes(LauncherState.mode)

                    visible: used
                    width: root.split ? 400 : parent.width
                    height: root.split ? parent.height
                        : count > 0 || headerItem ? Math.min(contentHeight + topMargin + bottomMargin, 540) : 0
                    topMargin: 6
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: used ? LauncherState.rows : []
                    header: LauncherState.mode === "calc" ? calcHeader : null

                    delegate: LauncherEntry {
                        required property var modelData
                        required property int index

                        width: list.width - list.leftMargin - list.rightMargin
                        row: modelData
                        first: index === 0
                        selected: root.selected === index
                        onPointed: point => root.point(point, index)
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
                    sourceComponent: LauncherState.mode === "clipboard" ? clipboardPreview
                        : LauncherState.mode === "windows" ? windowPreview : null
                }

                // Emoji mode: a grid of characters, in lines of `emojiView.perLine`
                // under section headers. Lines hold indexes into the rows.
                ListView {
                    id: emojiView

                    readonly property int perLine: 12
                    readonly property var lines: {
                        if (LauncherState.mode !== "emoji")
                            return [];
                        const lines = [];
                        let section = null;
                        let line = null;
                        LauncherState.rows.forEach((r, i) => {
                            if (r.section !== section) {
                                section = r.section;
                                lines.push({ header: true, title: section });
                                line = null;
                            }
                            if (!line || line.cells.length === perLine) {
                                line = { cells: [] };
                                lines.push(line);
                            }
                            line.cells.push(i);
                        });
                        return lines;
                    }
                    readonly property real cellWidth: (width - leftMargin - rightMargin - 4 * (perLine - 1)) / perLine

                    // Index of the line holding row `i`.
                    function lineOf(i) {
                        return lines.findIndex(l => l.cells?.includes(i));
                    }

                    // Up/down: same column in the next line of cells, clamped.
                    function step(dir) {
                        const from = lineOf(root.selected);
                        if (from < 0)
                            return;
                        const col = lines[from].cells.indexOf(root.selected);
                        for (let l = from + dir; l >= 0 && l < lines.length; l += dir) {
                            if (lines[l].cells) {
                                root.selected = lines[l].cells[Math.min(col, lines[l].cells.length - 1)];
                                positionViewAtIndex(l, ListView.Contain);
                                return;
                            }
                        }
                    }

                    visible: LauncherState.mode === "emoji"
                    width: parent.width
                    height: visible ? Math.min(contentHeight + topMargin + bottomMargin, 420) : 0
                    topMargin: 6
                    bottomMargin: 10
                    leftMargin: 14
                    rightMargin: 14
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: lines

                    delegate: Item {
                        id: line

                        required property var modelData
                        required property int index

                        width: emojiView.width - emojiView.leftMargin - emojiView.rightMargin
                        height: modelData.header ? (index === 0 ? 22 : 30) : emojiView.cellWidth * 0.86

                        PanelText {
                            visible: line.modelData.header ?? false
                            x: 4
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            text: line.modelData.title ?? ""
                            color: Style.subtle
                            font.pointSize: Style.fontSizeSmall - 1
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                        }

                        Row {
                            spacing: 4

                            Repeater {
                                model: line.modelData.cells ?? []

                                Rectangle {
                                    id: cell

                                    required property int modelData
                                    readonly property bool isSelected: root.selected === modelData

                                    width: emojiView.cellWidth
                                    height: line.height
                                    radius: 8
                                    color: isSelected ? Style.base02 : "transparent"
                                    border.width: isSelected ? 2 : 0
                                    border.color: Style.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: LauncherState.rows[cell.modelData]?.char ?? ""
                                        color: Style.base07
                                        font.family: Style.fontShell
                                        font.pixelSize: Math.round(cell.height * 0.5)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: mouse => root.point(mapToItem(null, mouse.x, mouse.y), cell.modelData)
                                        onClicked: LauncherState.activate(LauncherState.rows[cell.modelData], false)
                                    }
                                }
                            }
                        }
                    }
                }

                // Power mode: one tile per action, numbered for 1–5.
                Column {
                    id: powerView

                    visible: LauncherState.mode === "power"
                    width: parent.width
                    topPadding: 18
                    bottomPadding: 18
                    spacing: 14

                    Row {
                        id: tiles
                        x: 18
                        width: parent.width - 36
                        spacing: 10

                        Repeater {
                            model: powerView.visible ? LauncherState.rows : []

                            Rectangle {
                                id: tile

                                required property var modelData
                                required property int index
                                readonly property bool isSelected: root.selected === index
                                readonly property bool danger: modelData.power.confirm && isSelected

                                width: (tiles.width - tiles.spacing * 4) / 5
                                height: 120
                                radius: Style.radius
                                color: danger ? Style.alpha(Style.base08, 0.14) : isSelected ? Style.base02 : Style.alpha(Style.base02, 0.5)
                                border.width: isSelected ? 2 : 0
                                border.color: danger ? Style.base08 : Style.accent

                                Rectangle {
                                    x: 8
                                    y: 8
                                    implicitWidth: number.implicitWidth + 10
                                    implicitHeight: number.implicitHeight + 2
                                    radius: 4
                                    color: Style.base03

                                    PanelText {
                                        id: number
                                        anchors.centerIn: parent
                                        text: tile.index + 1
                                        color: Style.base06
                                        font.pointSize: Style.fontSizeSmall - 1
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    BarText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.glyph
                                        color: tile.danger ? Style.base08 : tile.isSelected ? Style.accent : Style.base06
                                        font.pixelSize: 30
                                    }

                                    PanelText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        textFormat: tile.modelData.titleHtml ? Text.StyledText : Text.PlainText
                                        text: tile.modelData.titleHtml || tile.modelData.title
                                        font.weight: Font.Medium
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selected = tile.index;
                                        LauncherState.activate(tile.modelData, false);
                                    }
                                }
                            }
                        }
                    }

                    // Second-Enter confirmation for log out, reboot, shut down.
                    Rectangle {
                        visible: LauncherPower.confirming !== ""
                        x: 18
                        width: parent.width - 36
                        height: 44
                        radius: 8
                        color: Style.alpha(Style.base08, 0.12)

                        BarText {
                            id: warnGlyph
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.warning
                            color: Style.base08
                            font.pixelSize: 16
                        }

                        PanelText {
                            anchors.left: warnGlyph.right
                            anchors.leftMargin: 10
                            anchors.right: confirmKeys.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: LauncherPower.confirmText
                        }

                        Row {
                            id: confirmKeys
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            KeyCaps {
                                anchors.verticalCenter: parent.verticalCenter
                                keys: ["↵"]
                            }

                            PanelText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "again to confirm"
                                color: Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }

                            KeyCaps {
                                anchors.verticalCenter: parent.verticalCenter
                                keys: ["Esc"]
                            }

                            PanelText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "cancel"
                                color: Style.subtle
                                font.pointSize: Style.fontSizeSmall
                            }
                        }
                    }
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
                                        onPointed: point => root.point(point, modelData)
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
                height: LauncherState.mode === "emoji" ? 60 : 40
                color: Style.alpha(Style.base01, 0.9)
                bottomLeftRadius: Style.radius - 2
                bottomRightRadius: Style.radius - 2

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Style.base02
                }

                // Emoji mode: the selected character, its name and keywords.
                Item {
                    visible: LauncherState.mode === "emoji"
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18

                    Text {
                        id: bigChar
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.current()?.char ?? ""
                        color: Style.base07
                        font.family: Style.fontShell
                        font.pixelSize: 30
                    }

                    Column {
                        anchors.left: bigChar.right
                        anchors.leftMargin: 14
                        anchors.right: copyKey.left
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        PanelText {
                            width: parent.width
                            text: root.current()?.title ?? ""
                            font.weight: Font.Medium
                        }

                        PanelText {
                            width: parent.width
                            text: root.current()?.detail ?? ""
                            color: Style.subtle
                            font.pointSize: Style.fontSizeSmall
                        }
                    }

                    Row {
                        id: copyKey
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        KeyCaps {
                            anchors.verticalCenter: parent.verticalCenter
                            keys: ["↵"]
                        }

                        PanelText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Copy"
                            color: Style.subtle
                            font.pointSize: Style.fontSizeSmall
                        }
                    }
                }

                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    visible: root.hints !== undefined

                    Repeater {
                        model: root.hints ?? []

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
                    visible: root.hints === undefined && LauncherState.mode !== "emoji"

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

    // Calc mode: the result above the history, with its other formats.
    Component {
        id: calcHeader

        Column {
            width: list.width - list.leftMargin - list.rightMargin
            topPadding: 10
            bottomPadding: 10
            spacing: 12

            Row {
                x: 10
                spacing: 14

                PanelText {
                    anchors.baseline: result.baseline
                    text: "="
                    color: Style.subtle
                    font.pointSize: Style.fontSize * 1.6
                }

                PanelText {
                    id: result
                    text: LauncherCalc.result || (LauncherCalc.expression === "" ? "" : "…")
                    color: Style.accent
                    font.pointSize: Style.fontSize * 2.6
                    font.bold: true
                }
            }

            Row {
                x: 10
                spacing: 8
                visible: LauncherCalc.choices.length > 1

                Repeater {
                    model: LauncherCalc.choices

                    Rectangle {
                        id: choice

                        required property var modelData
                        required property int index
                        readonly property bool chosen: LauncherCalc.format === index

                        implicitWidth: choiceRow.implicitWidth + 20
                        implicitHeight: choiceRow.implicitHeight + 10
                        radius: 6
                        color: chosen ? Style.base03 : Style.base02
                        border.width: chosen ? 1 : 0
                        border.color: Style.accent

                        Row {
                            id: choiceRow
                            anchors.centerIn: parent
                            spacing: 8

                            PanelText {
                                anchors.baseline: value.baseline
                                text: choice.modelData.label || "dec"
                                color: Style.subtle
                                font.pointSize: Style.fontSizeSmall - 1
                            }

                            PanelText {
                                id: value
                                text: choice.modelData.value
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: LauncherCalc.format = choice.index
                        }
                    }
                }
            }
        }
    }

    // Windows mode: a still of the selected window, where it is, and its keys.
    Component {
        id: windowPreview

        Item {
            id: wp

            readonly property var toplevel: root.current()?.toplevel ?? null
            readonly property var row: root.current()

            Rectangle {
                id: frame
                x: 18
                width: parent.width - 36
                anchors.top: parent.top
                anchors.topMargin: 18
                anchors.bottom: info.top
                anchors.bottomMargin: 14
                radius: 8
                color: Style.base00
                border.width: 1
                border.color: Style.base02
                clip: true

                ScreencopyView {
                    id: shot
                    readonly property real scale: Math.min((frame.width - 2) / Math.max(sourceSize.width, 1),
                        (frame.height - 2) / Math.max(sourceSize.height, 1))
                    anchors.centerIn: parent
                    width: sourceSize.width * scale
                    height: sourceSize.height * scale
                    captureSource: wp.toplevel?.wayland ?? null
                    live: true
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: !shot.hasContent
                    implicitSize: 64
                    source: wp.row?.icon ?? ""
                }
            }

            Column {
                id: info
                x: 18
                anchors.bottom: keys.top
                anchors.bottomMargin: 14
                width: parent.width - 36
                spacing: 4

                PanelText {
                    width: parent.width
                    text: wp.toplevel?.title ?? ""
                    font.weight: Font.Medium
                }

                PanelText {
                    width: parent.width
                    text: !wp.toplevel ? "" : [
                        LauncherWindows.workspaceLabel(wp.toplevel.workspace),
                        wp.toplevel.lastIpcObject?.floating ? "floating" : "tiled",
                        wp.toplevel.monitor?.name ?? ""
                    ].filter(t => t).join(" · ")
                    color: Style.subtle
                    font.pointSize: Style.fontSizeSmall
                }
            }

            Row {
                id: keys
                x: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 16

                Repeater {
                    model: [[["↵"], "Focus"], [["⇧", "1…0"], "Move to workspace"], [["Ctrl", "Q"], "Close"]]

                    Row {
                        id: windowKey

                        required property var modelData

                        spacing: 6

                        KeyCaps {
                            anchors.verticalCenter: parent.verticalCenter
                            keys: windowKey.modelData[0]
                        }

                        PanelText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: windowKey.modelData[1]
                            color: Style.subtle
                            font.pointSize: Style.fontSizeSmall
                        }
                    }
                }
            }
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

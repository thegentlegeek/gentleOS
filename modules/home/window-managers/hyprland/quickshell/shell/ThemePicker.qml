import Quickshell
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Theme picker (SUPER+W): choose a scheme and a wallpaper and see the
// wallpaper in it, then preview the theme on the desktop and keep or revert
// it. A window of its own, run as its own process (theme-picker.qml, started by
// gentle-theme open): a scheme preview restarts the shell but not this, so it
// stays where it is, and it follows the new colors through Style. gentle-theme
// (../theme.sh) does the work and reports through its state file.
FloatingWindow {
    id: root

    // The selection; starts at the theme of the active generation.
    property string scheme: Style.generation.scheme
    property string wallpaper: Style.generation.wallpaper
    property string query: ""
    // Store path of the latest wallpaper, or why the selection's couldn't be built,
    // and whether the selection's is still on its way.
    property string thumb: ""
    property string thumbError: ""
    property bool rendering: true
    property bool showSample: true
    property bool stateSeen: false

    // Whatever the wallpaper is doing, the selection's colors are at hand. A theme
    // set by hand might not be in the catalog.
    readonly property var selected: ThemeSchemes.schemes.find(s => s.id === scheme) ?? Style.generation
    readonly property bool busy: job.status === "building" || job.status === "keeping"
    // What's on the desktop: a wallpaper-only preview leaves the generation as it is.
    readonly property var live: job.status === "previewing" ? job : Style.generation
    readonly property bool applied: scheme === live.scheme && wallpaper === live.wallpaper
    readonly property bool trying: job.status === "previewing" && !busy
    readonly property bool canTry: !applied && !rendering && thumbError === "" && !busy
    readonly property var matches: {
        const shown = ThemeSchemes.schemes.filter(s => (!variants.value || s.variant === variants.value)
            && (!systems.value || s.id.startsWith(`${systems.value}/`)));
        const q = query.trim();
        if (!q)
            return shown;
        return shown.map(s => ({ s: s, m: Fuzzy.match(q, label(s.id)) }))
            .filter(x => x.m).sort((a, b) => b.m.score - a.m.score).map(x => x.s);
    }

    function label(id) {
        return id.slice(id.indexOf("/") + 1);
    }

    function run(...args) {
        Quickshell.execDetached([Settings.gentleTheme, ...args]);
        stateFile.reload();
    }

    function indexOf(id) {
        return matches.findIndex(s => s.id === id);
    }

    // A filter can hide the selection, which then has no row to show.
    function reveal(id, mode) {
        const i = indexOf(id);
        if (i >= 0)
            list.positionViewAtIndex(i, mode);
    }

    // Enter never keeps: gentle-theme keep commits before it asks for the password,
    // so that takes Ctrl+Enter.
    function handleKey(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const vertical = event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_Up ? -1 : 0;
        const horizontal = event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Left ? -1 : 0;
        if (event.key === Qt.Key_Escape) {
            visible = false;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (ctrl) {
                if (trying)
                    run("keep");
            } else if (query.trim() && matches.length && indexOf(scheme) < 0) {
                select(matches[0].id);
            } else if (canTry) {
                run("preview", scheme, wallpaper);
            }
        } else if (ctrl && event.key === Qt.Key_R) {
            if (trying)
                run("restore");
        } else if (ctrl && event.key === Qt.Key_S) {
            showSample = !showSample;
        } else if (vertical && matches.length) {
            select(matches[Math.max(0, Math.min(matches.length - 1, indexOf(scheme) + vertical))].id);
        } else if (horizontal && search.activeFocus && !search.text) {
            const wallpapers = Settings.themeWallpapers;
            wallpaper = wallpapers[Math.max(0, Math.min(wallpapers.length - 1, wallpapers.indexOf(wallpaper) + horizontal))];
        } else {
            return;
        }
        event.accepted = true;
    }

    function selectionChanged() {
        rendering = true;
        thumbError = "";
        thumbTimer.restart();
    }

    function select(id) {
        scheme = id;
        reveal(id, ListView.Contain);
    }

    title: "Theme Picker"
    implicitWidth: 860
    implicitHeight: 600
    minimumSize.width: 760
    minimumSize.height: 560
    color: Style.base00
    // Closing the window doesn't end the process by itself.
    onVisibleChanged: if (!visible) Qt.quit()
    Component.onCompleted: {
        search.forceActiveFocus();
        reveal(scheme, ListView.Center);
        thumbTimer.restart();
    }
    onSchemeChanged: selectionChanged()
    onWallpaperChanged: selectionChanged()

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 16
        focus: true
        Keys.onPressed: event => root.handleKey(event)

        SectionHeader {
            id: header
            title: "Theme"
            detail: `${root.label(root.live.scheme)} · ${root.live.wallpaper}`
        }

        Row {
            anchors.top: header.bottom
            anchors.bottom: footer.top
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            width: parent.width
            spacing: 16

            // Schemes: type to filter, arrows to move, click to pick.
            Column {
                id: schemes
                width: 380
                height: parent.height
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: Style.radius
                    color: Style.base01
                    border.width: 1
                    border.color: search.activeFocus ? Style.accent : Style.base03

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Style.fg
                        font.family: Style.fontShell
                        font.pointSize: Style.fontSize
                        clip: true
                        activeFocusOnTab: true
                        onTextChanged: root.query = text
                        Keys.forwardTo: [body]

                        PanelText {
                            visible: search.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${Icons.search}  ${root.matches.length} schemes`
                            color: Style.subtle
                        }
                    }
                }

                Row {
                    spacing: 8

                    Segments {
                        id: variants
                        options: [["Dark", "dark"], ["Light", "light"], ["Both", ""]]
                    }

                    Segments {
                        id: systems
                        options: [["Base16", "base16"], ["Base24", "base24"], ["All", ""]]
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: schemes.height - y
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.matches

                    delegate: SchemeRow {
                        width: list.width
                    }

                    PanelText {
                        visible: !root.matches.length
                        anchors.centerIn: parent
                        text: "No matching schemes"
                        color: Style.subtle
                    }
                }
            }

            // The selection on its wallpaper and its palette, and the wallpapers to pick from.
            Column {
                id: preview
                width: parent.width - schemes.width - parent.spacing
                height: parent.height
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: Math.min(width * 10 / 16, preview.height - paletteGrid.height - wallpaperChips.height - 2 * preview.spacing)
                    radius: Style.radius
                    color: root.selected.colors.base00
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.thumb ? "file://" + root.thumb : ""
                        sourceSize.width: width
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        retainWhileLoading: true
                    }

                    // In a corner: the middle of a wallpaper is usually its subject.
                    ThemeSample {
                        visible: root.showSample
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        colors: root.selected.colors
                    }

                    Chip {
                        id: sampleToggle
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "Sample"
                        selected: root.showSample
                        onClicked: root.showSample = !root.showSample
                    }

                    Rectangle {
                        visible: root.rendering || root.thumbError !== ""
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: Math.min(note.implicitWidth, parent.width - sampleToggle.width - 24)
                        height: note.implicitHeight
                        radius: 6
                        color: Style.base00

                        PanelText {
                            id: note
                            width: parent.width
                            padding: 6
                            wrapMode: Text.Wrap
                            text: root.thumbError || "Rendering…"
                            color: root.thumbError ? Style.base08 : Style.subtle
                            font.pointSize: Style.fontSizeSmall
                        }
                    }
                }

                Grid {
                    id: paletteGrid
                    width: parent.width
                    columns: 8
                    spacing: 4

                    Repeater {
                        model: ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "0A", "0B", "0C", "0D", "0E", "0F"]

                        delegate: Rectangle {
                            id: swatch

                            required property string modelData
                            readonly property color fill: root.selected.colors[`base${modelData}`]
                            readonly property color dark: root.selected.colors.base00
                            readonly property color light: root.selected.colors.base05

                            width: (paletteGrid.width - 7 * paletteGrid.spacing) / 8
                            height: 26
                            radius: 4
                            color: fill
                            border.width: 1
                            border.color: Style.alpha(Style.fg, 0.25)

                            PanelText {
                                anchors.centerIn: parent
                                text: swatch.modelData
                                color: Style.contrast(swatch.dark, swatch.fill) > Style.contrast(swatch.light, swatch.fill) ? swatch.dark : swatch.light
                                font.pointSize: Style.fontSizeSmall
                            }
                        }
                    }
                }

                Flow {
                    id: wallpaperChips
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: Settings.themeWallpapers

                        delegate: Chip {
                            required property string modelData

                            text: modelData
                            selected: modelData === root.wallpaper
                            onClicked: root.wallpaper = modelData
                        }
                    }
                }
            }
        }

        Column {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 8

            PanelText {
                visible: job.error !== ""
                width: parent.width
                text: job.error
                color: Style.base08
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            Item {
                width: parent.width
                height: 32

                PanelText {
                    anchors.left: parent.left
                    anchors.right: buttons.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Style.subtle
                    text: root.busy ? `${job.message}…`
                        : job.status === "previewing" ? `Trying ${root.label(job.scheme)} with ${job.wallpaper}`
                        : job.status === "kept" && job.ahead > 0 ? `Kept; ${job.ahead} commit(s) not pushed`
                        : job.status === "kept" && job.ahead < 0 ? "Kept; this branch has no upstream to push to"
                        : job.status === "kept" ? "Kept"
                        : ""
                }

                Row {
                    id: buttons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: !root.busy

                    Button {
                        visible: job.status === "kept" && job.ahead > 0
                        text: "Push"
                        onClicked: root.run("push")
                    }

                    Button {
                        visible: job.status === "previewing"
                        text: "Revert"
                        onClicked: root.run("restore")
                    }

                    Button {
                        visible: job.status === "previewing"
                        primary: root.applied
                        text: "Keep"
                        onClicked: root.run("keep")
                    }

                    Button {
                        visible: !(job.status === "previewing" && root.applied)
                        enabled: root.canTry
                        primary: root.canTry
                        text: "Try on desktop"
                        onClicked: root.run("preview", root.scheme, root.wallpaper)
                    }
                }
            }

            PanelText {
                width: parent.width
                text: "↑↓ scheme · ←→ wallpaper · Tab filters · Enter try · Ctrl+Enter keep · Ctrl+R revert · Ctrl+S sample · Esc close"
                color: Style.muted
                font.pointSize: Style.fontSizeSmall
            }
        }
    }

    component Chip: Rectangle {
        id: chip

        property string text
        property bool selected
        signal clicked

        implicitWidth: chipText.implicitWidth + 20
        implicitHeight: 28
        radius: Style.radius
        color: selected ? Style.highlight : chipArea.containsMouse ? Style.base02 : Style.base01

        PanelText {
            id: chipText
            anchors.centerIn: parent
            text: chip.text
            color: chip.selected ? Style.highlightText : Style.fg
            font.pointSize: Style.fontSizeSmall
        }

        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    // One choice out of options, each [label, value].
    component Segments: Rectangle {
        id: segments

        property var options
        property string value: ""

        implicitWidth: segmentRow.implicitWidth
        implicitHeight: 28
        radius: Style.radius
        color: Style.base01
        activeFocusOnTab: true
        Keys.onPressed: event => {
            const step = event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Left ? -1 : 0;
            if (!step)
                return;
            const values = options.map(o => o[1]);
            value = values[Math.max(0, Math.min(values.length - 1, values.indexOf(value) + step))];
            event.accepted = true;
        }

        Row {
            id: segmentRow

            Repeater {
                model: segments.options

                delegate: Rectangle {
                    id: segment

                    required property var modelData
                    readonly property bool selected: modelData[1] === segments.value

                    implicitWidth: segmentText.implicitWidth + 16
                    implicitHeight: segments.height
                    radius: Style.radius
                    color: selected ? Style.highlight : segmentArea.containsMouse ? Style.base02 : "transparent"

                    PanelText {
                        id: segmentText
                        anchors.centerIn: parent
                        text: segment.modelData[0]
                        color: segment.selected ? Style.highlightText : Style.fg
                        font.pointSize: Style.fontSizeSmall
                    }

                    MouseArea {
                        id: segmentArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: segments.value = segment.modelData[1]
                    }
                }
            }
        }

        // Over the segments, which would cover a border of this rectangle.
        Rectangle {
            visible: segments.activeFocus
            anchors.fill: parent
            radius: Style.radius
            color: "transparent"
            border.width: 1
            border.color: Style.accent
        }
    }

    // A scheme: its name, then its colors without having to render its
    // wallpaper. The chip has the scheme's own background and text, and its border
    // keeps it visible where that background matches this window's.
    component SchemeRow: Rectangle {
        id: row

        required property var modelData
        readonly property bool selected: modelData.id === root.scheme

        implicitHeight: 34
        radius: Style.radius
        color: rowArea.containsMouse ? Style.base02 : selected ? Style.base01 : "transparent"

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.scheme = row.modelData.id
        }

        Rectangle {
            visible: row.selected
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 18
            radius: 2
            color: Style.highlight
        }

        PanelText {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: systemTag.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.label(row.modelData.id)
            font.bold: row.selected
        }

        PanelText {
            id: systemTag
            anchors.right: chip.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.modelData.id.startsWith("base24/") ? "24" : ""
            color: Style.subtle
            font.pointSize: Style.fontSizeSmall
        }

        Rectangle {
            id: chip
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: chipColors.implicitWidth + 12
            height: 24
            radius: 6
            color: row.modelData.colors.base00
            border.width: 1
            border.color: Style.alpha(Style.fg, 0.25)

            Row {
                id: chipColors
                anchors.centerIn: parent
                spacing: 2

                PanelText {
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: 4
                    text: "Aa"
                    color: row.modelData.colors.base05
                    font.pointSize: Style.fontSizeSmall
                    font.bold: true
                }

                Repeater {
                    model: ["base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"]

                    delegate: Rectangle {
                        required property string modelData

                        anchors.verticalCenter: parent?.verticalCenter
                        width: 8
                        height: 14
                        radius: 2
                        color: row.modelData.colors[modelData]
                    }
                }
            }
        }
    }

    component Button: Rectangle {
        id: button

        property string text
        // The next step in the current state.
        property bool primary: false
        signal clicked

        implicitWidth: buttonText.implicitWidth + 28
        implicitHeight: 32
        radius: Style.radius
        opacity: enabled ? 1 : 0.4
        color: primary || buttonArea.containsMouse ? Style.highlight : Style.base02

        PanelText {
            id: buttonText
            anchors.centerIn: parent
            text: button.text
            color: button.primary || buttonArea.containsMouse ? Style.highlightText : Style.fg
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // gentle-theme's state, polled: the file is replaced or removed on every
    // change, which file watching doesn't follow.
    FileView {
        id: stateFile
        path: Settings.themeState
        blockLoading: true
        printErrors: false
        // Opened during a preview: start the selection at what's on the desktop.
        onLoaded: {
            if (!root.stateSeen && job.status === "previewing") {
                root.scheme = job.scheme;
                root.wallpaper = job.wallpaper;
            }
            root.stateSeen = true;
        }
        // No file: nothing in progress. Coming from a preview, it was reverted,
        // and the selection follows the generation back.
        onLoadFailed: {
            root.stateSeen = true;
            if (job.status === "previewing" || job.status === "building") {
                root.scheme = Qt.binding(() => Style.generation.scheme);
                root.wallpaper = Qt.binding(() => Style.generation.wallpaper);
            }
            job.status = "idle";
            job.error = "";
        }

        JsonAdapter {
            id: job
            property string status: "idle"
            property string scheme
            property string wallpaper
            property string message
            property string error
            property int ahead
        }
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        onTriggered: {
            stateFile.reload();
            Style.reload();
        }
    }

    // The wallpaper for the selection, once it has settled. A build still
    // running is stopped and the new one starts when it exits; the output
    // starts with the selection it's for, so a stale result can't land.
    function startThumb() {
        if (thumbProcess.running) {
            thumbProcess.pending = true;
            thumbProcess.running = false;
            return;
        }
        thumbProcess.command = [Settings.sh, "-c", 'echo "$1 $2"; exec "$0" thumb "$1" "$2" 2>/dev/null',
            Settings.gentleTheme, wallpaper, scheme];
        thumbProcess.running = true;
    }

    Timer {
        id: thumbTimer
        interval: 250
        onTriggered: root.startThumb()
    }

    Process {
        id: thumbProcess

        property bool pending: false

        onExited: {
            if (!pending)
                return;
            pending = false;
            root.startThumb();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const [key, path] = text.split("\n");
                if (thumbProcess.pending || key !== `${root.wallpaper} ${root.scheme}`)
                    return;
                root.rendering = false;
                root.thumb = path ?? "";
                if (!path)
                    root.thumbError = "Can't build this scheme, so it can't be applied.";
            }
        }
    }
}

import Quickshell
import Quickshell.Wayland
import QtQuick

// On-screen display for volume, brightness, the mic and the audio output, at
// the bottom centre of the focused monitor (state in OsdState.qml).
PanelWindow {
    id: root

    readonly property string kind: OsdState.kind
    readonly property bool hasLevel: kind !== "mic"
    readonly property real level: kind === "brightness" ? Brightness.level : Audio.volume
    readonly property bool dimmed: kind !== "brightness" && Audio.muted

    visible: OsdState.shown || card.opacity > 0
    screen: ShellState.focusedScreen
    anchors.bottom: true
    margins.bottom: 72
    exclusiveZone: 0
    implicitWidth: 340
    implicitHeight: 64
    color: "transparent"
    // Clicks pass through.
    mask: Region {}

    WlrLayershell.namespace: "gentle-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        id: card

        width: parent.width
        height: 56
        y: OsdState.shown ? 0 : 8
        opacity: OsdState.shown ? 1 : 0
        radius: Style.radius
        color: Style.panelBg
        border.width: 2
        border.color: Style.base0D

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        BarText {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text: root.kind === "brightness" ? Brightness.icon
                : root.kind === "mic" ? (Audio.micMuted ? Icons.micOff : Icons.mic)
                : Audio.icon
            color: root.kind === "mic" && Audio.micMuted ? Style.base08
                : root.dimmed ? Style.subtle : Style.accent
            font.pixelSize: 22
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 14
            anchors.right: percent.visible ? percent.left : parent.right
            anchors.rightMargin: percent.visible ? 10 : 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            PanelText {
                visible: root.kind === "mic" || root.kind === "output"
                width: parent.width
                text: root.kind === "mic" ? (Audio.micMuted ? "Microphone muted" : "Microphone on")
                    : Audio.sink?.description || Audio.sink?.nickname || Audio.sink?.name || "Audio output"
                font.pointSize: root.kind === "mic" ? Style.fontSize : Style.fontSizeSmall
                color: root.kind === "mic" ? Style.base07 : Style.base06
            }

            Rectangle {
                visible: root.hasLevel
                width: parent.width
                height: 8
                radius: 4
                color: Style.base02

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.level))
                    height: parent.height
                    radius: 4
                    color: root.dimmed ? Style.base03 : Style.accent

                    Behavior on width {
                        NumberAnimation { duration: 80 }
                    }
                }
            }
        }

        PanelText {
            id: percent
            visible: root.hasLevel
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: root.dimmed ? "Muted" : Math.round(root.level * 100) + "%"
            color: root.dimmed ? Style.subtle : Style.base07
            font.pointSize: root.dimmed ? Style.fontSizeSmall : Style.fontSize
        }
    }
}

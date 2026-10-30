import Quickshell
import Quickshell.Wayland
import QtQuick

// The centred password / confirm card shared by Pinentry.qml and Polkit.qml.
// Only one shows at a time: a prompt with work (`active`) takes
// ShellState.authOwner when it's free and gives it back when done.
PanelWindow {
    id: root

    // Unique per source ("pinentry", "polkit").
    required property string owner
    property bool active: false

    property string title
    property string description
    // A small line under the description (polkit's action id).
    property string detail
    property string error
    property string placeholder: "Password"
    // A text field (else Enter/Esc answer a confirm or message).
    property bool askInput: true
    property bool echo: false
    // Waiting on the answer just submitted.
    property bool busy: false
    property string okLabel: "OK"
    property string cancelLabel: "Cancel"
    property bool oneButton: false

    signal accepted(string text)
    signal cancelled

    readonly property string text: input.text

    function clear() {
        input.text = "";
    }

    function claim() {
        if (active && ShellState.authOwner === "")
            ShellState.authOwner = owner;
        else if (!active && ShellState.authOwner === owner)
            ShellState.authOwner = "";
    }

    onActiveChanged: claim()
    Component.onCompleted: claim()
    Connections {
        target: ShellState
        function onAuthOwnerChanged() {
            root.claim();
        }
    }

    visible: active && ShellState.authOwner === owner
    screen: ShellState.focusedScreen
    exclusiveZone: 0
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 4
    color: "transparent"

    WlrLayershell.namespace: "gentle-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        input.text = "";
        if (!visible)
            return;
        LauncherState.close();
        ShellState.openPanel = "";
        focusInput();
    }

    onAskInputChanged: focusInput()

    function focusInput() {
        if (askInput)
            input.forceActiveFocus();
        else
            keyCatcher.forceActiveFocus();
    }

    // Esc still cancels while busy.
    function answer(ok) {
        if (!ok)
            cancelled();
        else if (!busy)
            accepted(input.text);
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: Style.panelBg
        border.width: 2
        border.color: Style.base0D
    }

    Column {
        id: content

        x: 2
        y: 2
        width: parent.width - 4

        Column {
            width: parent.width
            padding: 20
            spacing: 12

            Row {
                spacing: 10

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.lock
                    color: Style.accent
                    font.pixelSize: 20
                }

                PanelText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    font.pointSize: Style.fontSizeTitle
                    font.bold: true
                }
            }

            PanelText {
                visible: text !== ""
                width: parent.width - 40
                text: root.description
                color: Style.base06
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            PanelText {
                visible: text !== ""
                width: parent.width - 40
                text: root.detail
                color: Style.subtle
                font.pointSize: Style.fontSizeSmall
            }

            PanelText {
                visible: text !== ""
                width: parent.width - 40
                text: root.error
                color: Style.base08
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            Rectangle {
                visible: root.askInput
                width: parent.width - 40
                height: 44
                radius: 8
                color: Style.base01
                border.width: 2
                border.color: input.activeFocus && !root.busy ? Style.accent : Style.base03

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: root.echo ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    readOnly: root.busy
                    color: root.busy ? Style.subtle : Style.fg
                    font.family: Style.fontShell
                    font.pointSize: Style.fontSize + 2
                    clip: true

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.answer(true);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.answer(false);
                            event.accepted = true;
                        }
                    }

                    PanelText {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.placeholder
                        color: Style.subtle
                        font.pointSize: input.font.pointSize
                    }
                }
            }
        }

        // Keys, in the launcher's footer style.
        Rectangle {
            width: parent.width
            height: 40
            color: Style.alpha(Style.base01, 0.9)
            bottomLeftRadius: Style.radius - 2
            bottomRightRadius: Style.radius - 2

            Row {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                visible: !root.busy

                Repeater {
                    model: [
                        [["↵"], root.okLabel],
                        [["Esc"], root.cancelLabel]
                    ].slice(0, root.oneButton ? 1 : 2)

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

            PanelText {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: root.busy
                text: "Checking…"
                color: Style.subtle
                font.pointSize: Style.fontSizeSmall
            }
        }
    }

    // Confirm and message prompts have no field to take the keys.
    Item {
        id: keyCatcher
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.answer(true);
            else if (event.key === Qt.Key_Escape)
                root.answer(false);
        }
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The shell's pinentry: the prompt gpg-agent and rbw use to ask for a
// passphrase. They run `pinentry-gentle` (../default.nix), which connects its
// stdin/stdout to this socket, so this side speaks pinentry's Assuan
// protocol: SET* lines describe the prompt, GETPIN/CONFIRM/MESSAGE show it.
// One prompt at a time; later requests wait their turn.
Scope {
    id: root

    // The request on screen: { socket, kind: "pin" | "confirm" | "message", oneButton }
    property var current: null
    property var queue: []

    readonly property var fields: current?.socket.fields ?? ({})

    SocketServer {
        active: true
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/gentle-pinentry.sock"

        handler: Socket {
            id: socket

            // SET* values by lowercase name (desc, prompt, title, error, ok…).
            property var fields: ({})
            property bool greeted: false

            function reply(text) {
                write(text);
                flush();
            }

            function greet() {
                if (connected && !greeted) {
                    greeted = true;
                    reply("OK Pleased to meet you\n");
                }
            }

            parser: SplitParser {
                onRead: line => root.command(socket, line)
            }

            onConnectedChanged: {
                if (connected)
                    greet();
                else
                    root.drop(socket);
            }
            Component.onCompleted: greet()
        }
    }

    // Assuan escapes %, CR and LF as %XX.
    function decode(s) {
        return s.replace(/%([0-9A-Fa-f]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
    }

    function encode(s) {
        return s.replace(/%/g, "%25").replace(/\r/g, "%0D").replace(/\n/g, "%0A");
    }

    // Shortcut markers in button labels ("_OK").
    function label(s, fallback) {
        return s ? s.replace(/_/g, "") : fallback;
    }

    function command(socket, line) {
        const space = line.indexOf(" ");
        const cmd = (space < 0 ? line : line.slice(0, space)).toUpperCase();
        const arg = space < 0 ? "" : decode(line.slice(space + 1));
        if (cmd === "")
            return;
        if (cmd.startsWith("SET")) {
            const fields = Object.assign({}, socket.fields);
            fields[cmd.slice(3).toLowerCase()] = arg;
            socket.fields = fields;
            socket.reply("OK\n");
            return;
        }
        switch (cmd) {
        case "OPTION":
            socket.reply("OK\n");
            break;
        case "RESET":
            socket.fields = {};
            socket.reply("OK\n");
            break;
        case "GETINFO": {
            const info = { pid: "0", version: "1.3.1", flavor: "gentle", ttyinfo: "- - -" }[arg];
            socket.reply(info !== undefined ? `D ${info}\nOK\n` : "OK\n");
            break;
        }
        case "GETPIN":
            enqueue({ socket, kind: "pin" });
            break;
        case "CONFIRM":
            enqueue({ socket, kind: "confirm", oneButton: arg.includes("--one-button") });
            break;
        case "MESSAGE":
            enqueue({ socket, kind: "message" });
            break;
        case "BYE":
            socket.reply("OK closing connection\n");
            socket.connected = false;
            break;
        default:
            socket.reply("ERR 536871187 Unknown IPC command <Pinentry>\n");
        }
    }

    function enqueue(request) {
        if (current)
            queue = queue.concat([request]);
        else
            current = request;
    }

    function next() {
        current = queue[0] ?? null;
        queue = queue.slice(1);
    }

    // The client went away (killed, or gpg-agent timed out).
    function drop(socket) {
        queue = queue.filter(r => r.socket !== socket);
        if (current?.socket === socket)
            next();
    }

    // ok: Enter (true) or Esc (false).
    function finish(ok) {
        const r = current;
        if (!r)
            return;
        if (r.kind === "pin")
            r.socket.reply(ok ? `D ${encode(input.text)}\nOK\n` : "ERR 83886179 Operation cancelled <Pinentry>\n");
        else if (r.kind === "confirm")
            r.socket.reply(ok || r.oneButton ? "OK\n" : "ERR 83886179 Operation cancelled <Pinentry>\n");
        else
            r.socket.reply("OK\n");
        input.text = "";
        // An error is shown once; the client sends it again if needed.
        const fields = Object.assign({}, r.socket.fields);
        delete fields.error;
        r.socket.fields = fields;
        next();
    }

    PanelWindow {
        id: window

        visible: root.current !== null
        screen: ShellState.focusedScreen
        exclusiveZone: 0
        implicitWidth: 520
        implicitHeight: content.implicitHeight + 4
        color: "transparent"

        WlrLayershell.namespace: "gentle-panel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (!visible)
                return;
            LauncherState.close();
            ShellState.openPanel = "";
            input.text = "";
            if (root.current.kind === "pin")
                input.forceActiveFocus();
            else
                keyCatcher.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Style.panelBg
            border.width: 2
            border.color: Style.base0E
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
                        text: root.fields.title || (root.current?.kind === "pin" ? "Password needed" : "Confirm")
                        font.pointSize: Style.fontSizeTitle
                        font.bold: true
                    }
                }

                PanelText {
                    visible: text !== ""
                    width: parent.width - 40
                    text: root.fields.desc ?? ""
                    color: Style.base06
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }

                PanelText {
                    visible: text !== ""
                    width: parent.width - 40
                    text: root.fields.error ?? ""
                    color: Style.base08
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }

                Rectangle {
                    visible: root.current?.kind === "pin"
                    width: parent.width - 40
                    height: 44
                    radius: 8
                    color: Style.base01
                    border.width: 2
                    border.color: input.activeFocus ? Style.accent : Style.base03

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Style.base07
                        font.family: Style.fontShell
                        font.pointSize: Style.fontSize + 2
                        clip: true

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.finish(true);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.finish(false);
                                event.accepted = true;
                            }
                        }

                        PanelText {
                            visible: input.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.fields.prompt ?? "").replace(/:\s*$/, "") || "Password"
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

                    Repeater {
                        model: [
                            [["↵"], root.label(root.fields.ok, "OK")],
                            [["Esc"], root.label(root.fields.cancel, "Cancel")]
                        ].slice(0, root.current?.kind === "message" || root.current?.oneButton ? 1 : 2)

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
            }
        }

        // Confirm and message prompts have no field to take the keys.
        Item {
            id: keyCatcher
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.finish(true);
                else if (event.key === Qt.Key_Escape)
                    root.finish(false);
            }
        }
    }
}

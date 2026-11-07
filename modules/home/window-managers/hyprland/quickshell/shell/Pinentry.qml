import Quickshell
import Quickshell.Io
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
            // Like pinentry, commands run one at a time: lines that arrive
            // while a prompt is open wait here.
            property bool busy: false
            property var backlog: []

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
        if (socket.busy) {
            socket.backlog = socket.backlog.concat([line]);
            return;
        }
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
        request.socket.busy = true;
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
            r.socket.reply(ok ? `D ${encode(prompt.text)}\nOK\n` : "ERR 83886179 Operation cancelled <Pinentry>\n");
        else if (r.kind === "confirm")
            r.socket.reply(ok || r.oneButton ? "OK\n" : "ERR 83886179 Operation cancelled <Pinentry>\n");
        else
            r.socket.reply("OK\n");
        prompt.clear();
        // An error is shown once; the client sends it again if needed.
        const fields = Object.assign({}, r.socket.fields);
        delete fields.error;
        r.socket.fields = fields;
        next();
        resume(r.socket);
    }

    // Run the lines that waited for the answered prompt, up to the next one.
    function resume(socket) {
        socket.busy = false;
        while (!socket.busy && socket.backlog.length > 0) {
            const line = socket.backlog[0];
            socket.backlog = socket.backlog.slice(1);
            command(socket, line);
        }
    }

    AuthPrompt {
        id: prompt

        owner: "pinentry"
        active: root.current !== null
        title: root.fields.title || (root.current?.kind === "pin" ? "Password needed" : "Confirm")
        description: root.fields.desc ?? ""
        error: root.fields.error ?? ""
        placeholder: (root.fields.prompt ?? "").replace(/:\s*$/, "") || "Password"
        askInput: root.current?.kind === "pin"
        okLabel: root.label(root.fields.ok, "OK")
        cancelLabel: root.label(root.fields.cancel, "Cancel")
        oneButton: root.current?.kind === "message" || (root.current?.oneButton ?? false)

        onAccepted: root.finish(true)
        onCancelled: root.finish(false)
    }
}

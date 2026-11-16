pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.audio != null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property bool headphones: isBluetooth(sink)

    // Hardware outputs to pick from (no app streams, no video nodes).
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.type === PwNodeType.AudioSink)
        .sort((a, b) => label(a).localeCompare(label(b)))

    function isBluetooth(node) {
        return (node?.name ?? "").startsWith("bluez");
    }

    function label(node) {
        return node?.nickname || node?.description || node?.name || "";
    }

    // Makes `node` the configured default (like `wpctl set-default`), which the
    // volume keys, the OSD and the slider follow. WirePlumber remembers it.
    //
    // Then moves everything that's playing there too. A stream moved to a
    // device before (in pavucontrol, say) is pinned to it, and WirePlumber
    // pins that app's later streams the same way. Removing the pin sends the
    // stream to the default, and WirePlumber forgets the app's saved one.
    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
        for (const n of Pipewire.nodes.values) {
            if (n.type === PwNodeType.AudioOutStream)
                Quickshell.execDetached([Settings.pwMetadata, "-d", String(n.id), "target.object"]);
        }
    }

    readonly property string icon: muted ? Icons.volumeMuted
        : headphones ? Icons.headphones
        : Icons.volume[Math.min(2, Math.floor(volume * 3))]

    // Capped at 100%, like the volume keys (wpctl -l 1).
    function setVolume(v) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // A node's audio properties are only kept up to date while it's tracked.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}

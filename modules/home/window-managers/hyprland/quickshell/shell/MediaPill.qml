import Quickshell.Services.Mpris
import QtQuick

// Playing player first, else the first one. playerctld's proxy shows up as a
// player of its own; skip it (it mirrors whichever player is active).
Pill {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null

    function pad(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function time(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60;
        return h > 0 ? `${h}:${pad(m)}:${pad(sec)}` : `${pad(m)}:${pad(sec)}`;
    }

    function elide(s, n) {
        return s.length > n ? s.slice(0, n - 1) + "…" : s;
    }

    visible: player !== null
    italic: !(player?.isPlaying ?? false)
    text: {
        if (!player)
            return "";
        let t = (player.isPlaying ? Icons.playing : Icons.paused) + " " + elide(player.trackTitle || player.identity, 40);
        if (player.lengthSupported && player.length > 0)
            t += ` ${time(player.position)}/${time(player.length)}`;
        return t;
    }
    tooltip: player ? `Artist: ${player.trackArtist}\nAlbum: ${player.trackAlbum}\nTitle: ${player.trackTitle}` : ""

    onClicked: m => {
        if (m.button === Qt.RightButton)
            player.next();
        else if (m.button === Qt.MiddleButton)
            player.previous();
        else
            player.togglePlaying();
    }

    // MPRIS doesn't push position updates; re-read it while playing.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}

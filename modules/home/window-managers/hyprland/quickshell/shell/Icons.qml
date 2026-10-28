pragma Singleton

import Quickshell
import QtQuick

// Nerd Font glyphs. Font Awesome ones are the same as the old Waybar config;
// Material Design (0xF0000+) codepoints are from Nerd Fonts' glyphnames.json.
Singleton {
    function g(cp) {
        return String.fromCodePoint(cp);
    }

    readonly property string wsUrgent: g(0xF06A)
    readonly property string wsActive: g(0xF192)
    readonly property string wsDefault: g(0xF111)

    readonly property string playing: "▶"
    readonly property string paused: "⏸"
    readonly property string play: g(0xF040A)
    readonly property string pause: g(0xF03E4)
    readonly property string next: g(0xF04AD)
    readonly property string prev: g(0xF04AE)

    readonly property var volume: [g(0xF026), g(0xF027), g(0xF028)]
    readonly property string volumeMuted: g(0xF075F)
    readonly property string headphones: g(0xF025)
    readonly property string mic: g(0xF036C)
    readonly property string micOff: g(0xF036D)

    readonly property string wifi: g(0xF1EB)
    readonly property string wifiOff: g(0xF05AA)
    // Signal 0..4 bars.
    readonly property var wifiStrength: [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
    readonly property string ethernet: g(0xEF44)
    readonly property string warning: "⚠"
    readonly property string bluetooth: g(0xF00AF)
    readonly property string bluetoothOff: g(0xF00B2)

    readonly property string cpu: g(0xF2DB)
    readonly property var temperature: [g(0xF2CB), g(0xF2C9), g(0xF2C7)]
    readonly property var backlight: [g(0xE38D), g(0xE3D3), g(0xE3D1), g(0xE3CF), g(0xE3CE), g(0xE3CD), g(0xE3CA), g(0xE3C8), g(0xE39B)]
    readonly property var battery: [g(0xF244), g(0xF243), g(0xF242), g(0xF241), g(0xF240)]
    readonly property string charging: g(0xF0084)
    readonly property string plugged: g(0xF1E6)

    readonly property string profilePerformance: g(0xF0E7)
    readonly property string profileBalanced: g(0xF24E)
    readonly property string profileSaver: g(0xF06C)

    readonly property string capsLock: g(0xF023)
    readonly property string caffeineOn: g(0xF06E)
    readonly property string caffeineOff: g(0xF070)

    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string tune: g(0xF1542)
    readonly property string cog: g(0xF0493)
    readonly property string close: g(0xF0156)
    readonly property string chevron: g(0xF0142)
    readonly property string clearAll: g(0xF05E9)

    readonly property string power: "⏻"
    readonly property string lock: g(0xF033E)
    readonly property string logout: g(0xF0343)
    readonly property string sleep: g(0xF0904)
    readonly property string reboot: g(0xF0709)
}

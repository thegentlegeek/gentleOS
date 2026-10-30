pragma Singleton

import Quickshell
import QtQuick

// Typed view of Theme.qml.json, which Nix generates from Stylix (../default.nix).
// Components use this rather than Theme directly so colors are real `color`s.
Singleton {
    id: root

    readonly property color base00: Theme.colors.base00
    readonly property color base01: Theme.colors.base01
    readonly property color base02: Theme.colors.base02
    readonly property color base03: Theme.colors.base03
    readonly property color base04: Theme.colors.base04
    readonly property color base05: Theme.colors.base05
    readonly property color base06: Theme.colors.base06
    readonly property color base07: Theme.colors.base07
    readonly property color base08: Theme.colors.base08
    readonly property color base09: Theme.colors.base09
    readonly property color base0A: Theme.colors.base0A
    readonly property color base0B: Theme.colors.base0B
    readonly property color base0C: Theme.colors.base0C
    readonly property color base0D: Theme.colors.base0D
    readonly property color base0E: Theme.colors.base0E
    readonly property color base0F: Theme.colors.base0F

    readonly property string fontMono: Theme.fontMono
    readonly property string fontShell: Theme.fontShell
    readonly property string fontSans: Theme.fontSans
    readonly property int fontSizeBar: Theme.fontSizeBar
    // Popup/panel text, in points (Stylix's popups size).
    readonly property real fontSize: Theme.fontSizePopups
    readonly property real fontSizeSmall: Theme.fontSizePopups - 1
    readonly property real fontSizeTitle: Theme.fontSizePopups + 2

    readonly property real barAlpha: Theme.barAlpha
    readonly property real popupAlpha: Theme.popupAlpha
    readonly property int radius: Theme.radius

    // Light text: the lightest of base05-base07. base07 alone is an accent or a
    // dark tone in some schemes (Nord, Rosé Pine).
    readonly property color fg: [base05, base06, base07].reduce((a, b) => _y(b) > _y(a) ? b : a)

    // Filled pills with text on them (clock, focused workspace, notification
    // popups): base0D/base08 with whichever of base00/fg reads better, and the
    // fill's lightness nudged a little if that still isn't enough. See legible().
    // (Not onHighlight/onAlert: QML takes on<Capital> names as signal handlers.)
    readonly property var _highlight: legible(base0D)
    readonly property color highlight: _highlight.fill
    readonly property color highlightText: _highlight.text
    readonly property var _alert: legible(base08)
    readonly property color alert: _alert.fill
    readonly property color alertText: _alert.text

    readonly property color panelBg: alpha(base00, popupAlpha)
    // Bar modules share one surface; color is reserved for state.
    readonly property color pillBg: base02
    readonly property color muted: base04
    // Secondary text in the launcher: base04/base05 are too dim to read on the
    // panel background in some schemes (Lime's base05 is 4.2:1).
    readonly property color subtle: mix(base05, base06, 0.3)
    // Launcher search matches, the selected row's icon and the active mode.
    readonly property color accent: base0B

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // APCA lightness contrast (|Lc|, 0-106) of text on bg. WCAG 2 ratios
    // undercount light text on mid-tone colors, which is most base16 accents.
    // Lc 45 is the usual floor for short bold labels, 60 is comfortable.
    function contrast(text, bg) {
        const yt = _y(text), yb = _y(bg);
        if (Math.abs(yb - yt) < 0.0005)
            return 0;
        const s = yb > yt ? (Math.pow(yb, 0.56) - Math.pow(yt, 0.57)) * 1.14
            : (Math.pow(yb, 0.65) - Math.pow(yt, 0.62)) * 1.14;
        return Math.abs(s) < 0.1 ? 0 : (Math.abs(s) - 0.027) * 100;
    }

    // A fill for `bg` and text to put on it: base00 or fg, whichever reads
    // better, then the fill's OKLab lightness (hue and chroma kept) moved away
    // from the text until it reaches Lc 55. The nudge is capped so the fill
    // stays recognizably the scheme's color; most schemes need none.
    function legible(bg) {
        const text = contrast(base00, bg) > contrast(fg, bg) ? base00 : fg;
        const lab = _toOklab(bg);
        const step = _y(text) > _y(bg) ? -0.005 : 0.005;
        let fill = bg, l = lab.l;
        while (contrast(text, fill) < 55 && Math.abs(l - lab.l) < 0.12 && l > 0.02 && l < 0.98) {
            l += step;
            fill = _fromOklab(l, lab.a, lab.b);
        }
        return { fill: fill, text: text };
    }

    // APCA screen luminance.
    function _y(c) {
        const y = 0.2126729 * Math.pow(c.r, 2.4) + 0.7151522 * Math.pow(c.g, 2.4) + 0.072175 * Math.pow(c.b, 2.4);
        return y < 0.022 ? y + Math.pow(0.022 - y, 1.414) : y;
    }

    function _toOklab(c) {
        const lin = x => x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4);
        const r = lin(c.r), g = lin(c.g), b = lin(c.b);
        const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
        const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
        const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
        return {
            l: 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
            a: 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
            b: 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s
        };
    }

    function _fromOklab(L, a, b) {
        const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
        const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
        const s = Math.pow(L - 0.0894841775 * a - 1.291485548 * b, 3);
        const gam = x => Math.min(1, Math.max(0, x <= 0.0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - 0.055));
        return Qt.rgba(gam(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
            gam(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
            gam(-0.0041960771 * l - 0.7034186147 * m + 1.707614701 * s), 1);
    }
}

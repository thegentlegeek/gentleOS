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

    readonly property color panelBg: alpha(base00, popupAlpha)
    // Bar modules share one surface; color is reserved for state.
    readonly property color pillBg: base02
    readonly property color muted: base04

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}

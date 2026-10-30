import QtQuick

// Text inside panels and notifications (Stylix popups font size).
Text {
    color: Style.fg
    font.family: Style.fontShell
    font.pointSize: Style.fontSize
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}

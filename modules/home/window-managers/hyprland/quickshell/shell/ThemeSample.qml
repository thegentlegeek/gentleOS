import QtQuick

// A fixed prompt and bit of code in a scheme's colors, by the base16 style roles.
// Instant, as it needs no build. Each app maps these colors its own way, so this
// shows a scheme's character and contrast rather than exactly how an app looks.
Rectangle {
    id: root

    // base00-base0F of the scheme.
    required property var colors

    readonly property var lines: [
        [["~/gentleOS ", "base0D"], ["main ", "base0E"], ["$ ls", "base05"]],
        [["fn ", "base0E"], ["greet", "base0D"], ["(name) {", "base05"]],
        [["  // say hello", "base03"]],
        [["  print(", "base05"], ["\"hi\"", "base0B"], [", ", "base05"], ["42", "base09"], [")", "base05"]],
        [["}", "base05"]],
        [["error: ", "base08"], ["not found", "base05"]]
    ]

    implicitWidth: sample.implicitWidth + 24
    implicitHeight: sample.implicitHeight + 20
    radius: Style.radius
    color: colors.base00
    border.width: 1
    border.color: colors.base03

    Text {
        id: sample
        anchors.centerIn: parent
        textFormat: Text.StyledText
        font.family: Style.fontMono
        font.pointSize: Style.fontSizeSmall
        text: root.lines.map(line => line.map(([text, role]) =>
            `<font color="${root.colors[role]}">${text.replace(/ /g, "&nbsp;").replace(/"/g, "&quot;")}</font>`).join("")).join("<br>")
    }
}

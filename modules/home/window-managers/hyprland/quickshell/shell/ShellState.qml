pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // The open panel: "", "quickSettings", "notifications" or "session".
    property string openPanel: ""
    // Holds a Wayland idle inhibitor on the bar (hypridle honours it).
    property bool caffeine: false

    // Panels open on the monitor that has focus.
    readonly property ShellScreen focusedScreen:
        Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // Clicking a bar button while its panel is open first clears the panel's
    // focus grab (closing it), then delivers the click, which would reopen it.
    property string lastClosed: ""
    property real lastClosedAt: 0

    function toggle(panel) {
        if (openPanel === panel) {
            openPanel = "";
            return;
        }
        if (lastClosed === panel && Date.now() - lastClosedAt < 300)
            return;
        openPanel = panel;
    }

    function close(panel) {
        if (openPanel !== panel)
            return;
        openPanel = "";
        lastClosed = panel;
        lastClosedAt = Date.now();
    }

    function run(command) {
        openPanel = "";
        Quickshell.execDetached(command);
    }
}

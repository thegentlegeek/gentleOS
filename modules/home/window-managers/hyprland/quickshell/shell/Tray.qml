import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// Status notifier items (blueman etc.). Left click activates, right click (or
// left on menu-only items) opens the item's menu, middle click is secondary.
// Items listed in Settings.trayHidden are left out.
Row {
    id: root

    required property QsWindow bar

    spacing: 10

    Repeater {
        model: SystemTray.items.values.filter(i => {
            const name = (i.id + " " + i.title).toLowerCase();
            return !Settings.trayHidden.some(h => name.includes(h.toLowerCase()));
        })

        delegate: Item {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: 18
            implicitHeight: 24

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: entry.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    const item = entry.modelData;
                    if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (m.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            const p = entry.mapToItem(null, 0, entry.height);
                            item.display(root.bar, p.x, p.y + 8);
                        }
                    } else {
                        item.activate();
                    }
                }
                onWheel: w => entry.modelData.scroll(w.angleDelta.y, false)
            }

            Tooltip {
                target: entry
                text: entry.modelData.tooltipTitle || entry.modelData.title
                hovered: hover.hovered
            }

            HoverHandler {
                id: hover
            }
        }
    }
}

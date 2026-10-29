import Quickshell
import QtQuick

// Month view under the clock. Arrows (or scrolling) change month; clicking the
// month name goes back to today.
PanelFrame {
    id: root

    property date today: new Date()
    // First day of the month being shown.
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7

    // The 42 days (6 weeks) of the grid.
    readonly property var days: {
        const offset = (month.getDay() - firstWeekday + 7) % 7;
        const start = new Date(month.getFullYear(), month.getMonth(), 1 - offset);
        return Array.from({ length: 42 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
    }

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    name: "calendar"
    alignRight: false
    panelWidth: 320
    onOpenChanged: if (open) {
        today = new Date();
        month = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    PanelText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDate(root.today, "dddd, MMMM d, yyyy")
        font.pointSize: Style.fontSizeTitle
        font.bold: true
    }

    Item {
        width: parent.width
        height: 28

        Pill {
            anchors.left: parent.left
            padding: 10
            text: "‹"
            onClicked: root.shift(-1)
        }

        Pill {
            anchors.centerIn: parent
            color: "transparent"
            text: Qt.formatDate(root.month, "MMMM yyyy")
            tooltip: "Back to today"
            onClicked: root.shift((root.today.getFullYear() - root.month.getFullYear()) * 12 + root.today.getMonth() - root.month.getMonth())
        }

        Pill {
            anchors.right: parent.right
            padding: 10
            text: "›"
            onClicked: root.shift(1)
        }
    }

    Item {
        width: parent.width
        height: grid.height

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: w => root.shift(w.angleDelta.y > 0 ? -1 : 1)
        }

        Grid {
            id: grid

            readonly property real cell: width / 7

            width: parent.width
            columns: 7

            Repeater {
                model: 7

                delegate: PanelText {
                    required property int index

                    width: grid.cell
                    height: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((root.firstWeekday + index) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Style.muted
                    font.pointSize: Style.fontSizeSmall
                }
            }

            Repeater {
                model: root.days

                delegate: Item {
                    id: day

                    required property date modelData
                    readonly property bool inMonth: modelData.getMonth() === root.month.getMonth()
                    readonly property bool isToday: modelData.toDateString() === root.today.toDateString()

                    width: grid.cell
                    height: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 15
                        color: day.isToday ? Style.base0D : "transparent"
                    }

                    PanelText {
                        anchors.centerIn: parent
                        text: day.modelData.getDate()
                        color: day.inMonth ? Style.base07 : Style.base03
                        font.bold: day.isToday
                    }
                }
            }
        }
    }
}

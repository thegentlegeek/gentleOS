import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick

// One notification, as a popup (times out, dunst's colors) or in the center.
// Clicking runs the default action if there is one; X dismisses it for good.
Rectangle {
    id: root

    required property Notification notif
    property bool popup: false

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property var actions: notif.actions.filter(a => a.identifier !== "default")
    readonly property var defaultAction: notif.actions.find(a => a.identifier === "default") ?? null
    readonly property string iconSource: {
        const i = notif.appIcon;
        if (i === "")
            return "";
        if (i.startsWith("/"))
            return "file://" + i;
        if (i.includes("://"))
            return i;
        return Quickshell.iconPath(i, true);
    }

    implicitHeight: layout.implicitHeight + 24
    radius: Style.radius
    color: popup ? Style.alpha(critical ? Style.base08 : Style.base0D, Style.popupAlpha)
        : critical ? Style.alpha(Style.base08, 0.4) : Style.base01
    border.width: popup ? 0 : 1
    border.color: critical ? Style.base08 : Style.base02

    HoverHandler {
        id: hover
    }

    // Popups stay while hovered; critical ones until clicked or dismissed.
    Timer {
        running: root.popup && !root.critical && !hover.hovered
        interval: root.notif.expireTimeout > 0 ? root.notif.expireTimeout * 1000 : 5000
        onTriggered: Notifs.hidePopup(root.notif)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.defaultAction) {
                root.defaultAction.invoke();
                if (!root.notif.resident)
                    root.notif.dismiss();
            } else if (root.popup) {
                Notifs.hidePopup(root.notif);
            }
        }
    }

    Column {
        id: layout

        x: 12
        y: 12
        width: parent.width - 24
        spacing: 8

        Row {
            width: parent.width
            spacing: 10

            IconImage {
                id: image
                visible: source != ""
                implicitSize: 40
                source: root.notif.image || root.iconSource
            }

            Column {
                width: parent.width - (image.visible ? image.width + parent.spacing : 0) - closeButton.width
                spacing: 2

                PanelText {
                    width: parent.width
                    text: root.notif.appName
                    font.pointSize: Style.fontSizeSmall
                    opacity: 0.75
                }

                PanelText {
                    width: parent.width
                    text: root.notif.summary
                    font.bold: true
                }

                PanelText {
                    width: parent.width
                    visible: text !== ""
                    text: root.notif.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 4 : 8
                }
            }

            Rectangle {
                id: closeButton
                width: 24
                height: 24
                radius: 12
                color: closeArea.containsMouse ? Style.alpha(Style.base00, 0.3) : "transparent"

                BarText {
                    anchors.centerIn: parent
                    text: Icons.close
                    font.pixelSize: 14
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notif.dismiss()
                }
            }
        }

        Row {
            visible: root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: action

                    required property NotificationAction modelData

                    width: actionText.implicitWidth + 24
                    height: 28
                    radius: Style.radius
                    color: actionArea.containsMouse ? Style.alpha(Style.base00, 0.4) : Style.alpha(Style.base00, 0.2)

                    PanelText {
                        id: actionText
                        anchors.centerIn: parent
                        text: action.modelData.text
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            action.modelData.invoke();
                            if (!root.notif.resident)
                                root.notif.dismiss();
                        }
                    }
                }
            }
        }
    }
}

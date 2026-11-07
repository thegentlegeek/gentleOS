pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification server (replaces dunst). Every notification stays in the
// history (notification center) until dismissed; popups are a separate,
// shorter-lived list.
Singleton {
    id: root

    // Newest first.
    readonly property var history: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    // Do not disturb: no popups except critical ones; history still fills.
    property bool dnd: false

    readonly property int maxPopups: 5

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
        // Transient notifications don't belong in the history.
        if (n.transient)
            n.expire();
    }

    function clearAll() {
        for (const n of history)
            n.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.popups = root.popups.filter(p => p !== n));
            // Carried over from before a config reload: already shown once.
            if (n.lastGeneration)
                return;
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return;
            root.popups = [n].concat(root.popups).slice(0, root.maxPopups);
        }
    }
}

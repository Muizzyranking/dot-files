pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.core

// Notification server. Everything is kept until dismissed. Do not disturb only
// silences sounds (and, later, island toasts); notifications are still stored.
Singleton {
    id: root
    property bool dnd: Config.v.notifications.dnd
    property var times: ({})
    property real started: Date.now()
    property real now: Date.now()
    readonly property var model: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    function iconSrc(n) {
        return n.image !== "" ? n.image : n.appIcon === "" ? ""
            : n.appIcon.startsWith("/") ? n.appIcon : Quickshell.iconPath(n.appIcon, true)
    }
    function toggleDnd() { dnd = !dnd }
    function clearAll() { for (const n of Array.from(server.trackedNotifications.values)) n.dismiss() }
    function ago(id, ref) {
        const t = times[id]
        if (!t) return ""
        const s = Math.floor((ref - t) / 1000)
        if (s < 60) return "now"
        const m = Math.floor(s / 60)
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d"
    }

    Timer { running: true; repeat: true; interval: 30000; onTriggered: root.now = Date.now() }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
        onNotification: n => {
            n.tracked = true
            const t = Object.assign({}, root.times)
            t[n.id] = Date.now()
            root.times = t
            root.now = Date.now()
            // forget timestamps of notifications that no longer exist
            const live = new Set(server.trackedNotifications.values.map(x => String(x.id)))
            for (const k in t) if (!live.has(k)) delete t[k]
            // After a shell reload, notifications that were already there are announced again.
            // They are kept in the panel, but must not pop up as new toasts.
            const restored = n.lastGeneration === true || (Date.now() - root.started < 1500)
            if (restored) return
            const critical = n.urgency === NotificationUrgency.Critical
            Sounds.notify(critical)
            if (!root.dnd || critical) Toasts.show(n)
        }
    }
}

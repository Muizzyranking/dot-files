pragma Singleton
import Quickshell
import QtQuick
import qs.core

// The notification currently shown by the island. A plain copy (snap) is kept for
// display, so nothing reads a notification object after it has been dismissed.
Singleton {
    id: root
    property var current: null
    property var snap: ({ id: -1, appName: "", icon: "", summary: "", body: "" })
    property int hoverCount: 0
    property string screenName: ""      // monitor that was focused when the toast arrived
    property bool _wasFull: false
    readonly property bool hovered: hoverCount > 0

    function showsOn(name) {
        const m = Config.v.toasts.monitor
        return m === "all" || (m === "primary" ? Monitors.isPrimary(name) : name === screenName)
    }
    function hover(on) { hoverCount = Math.max(0, hoverCount + (on ? 1 : -1)) }
    function show(n) {
        if (!Config.v.toasts.enabled) return
        snap = { id: n.id, appName: n.appName, icon: Notifs.iconSrc(n), summary: n.summary, body: n.body }
        current = n
        screenName = Hypr.focusedScreen()
        timer.restart()
    }
    function clear() {
        current = null
        if (IslandState.expanded === "toast") IslandState.collapse()
    }
    function dismissCurrent() {
        const n = current
        clear()
        if (n) n.dismiss()
    }

    Timer {
        id: timer
        interval: IslandState.expanded === "toast" ? Config.v.toasts.expandedTimeoutMs : Config.v.toasts.timeoutMs
        onTriggered: { if (root.hovered) restart(); else root.clear() }
    }
    Connections {
        target: IslandState
        function onExpandedChanged() {
            const full = IslandState.expanded === "toast"
            if (full) timer.restart()
            else if (root._wasFull) root.clear()
            root._wasFull = full
        }
    }
    Connections {
        target: root.current
        ignoreUnknownSignals: true
        function onClosed() { root.clear() }
    }
}

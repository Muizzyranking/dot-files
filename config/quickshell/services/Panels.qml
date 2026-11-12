pragma Singleton
import Quickshell
import QtQuick

// Which panel is open, on which screen, and where it should hang from.
Singleton {
    property string open: ""
    property string screenName: ""
    property real anchorX: 0

    function toggle(name, scr, x) {
        if (open === name && screenName === scr) { open = ""; return; }
        screenName = scr
        anchorX = x
        open = name
    }
    function closeAll() { open = "" }
    function show(name) { open = name }
    function openAt(name, scr, x) { screenName = scr; anchorX = x; open = name }
    function toggleFocused(name) {
        const s = Hypr.focusedScreen()
        if (open === name && screenName === s) { open = ""; return }
        openAt(name, s, Hypr.centerX(s))
    }
    function close() { open = "" }
}

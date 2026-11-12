pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string open: ""
    property string screenName: ""
    function toggle(name) {
        if (open === name) { open = ""; return };
        screenName = Hypr.focusedScreen()
        open = name
    }
    function close() { open = "" }
}

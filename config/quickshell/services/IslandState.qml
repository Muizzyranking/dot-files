pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string expanded: ""
    property string screenName: ""
    function expand(mode, scr) { screenName = scr; expanded = mode }
    function collapse() { expanded = "" }
}

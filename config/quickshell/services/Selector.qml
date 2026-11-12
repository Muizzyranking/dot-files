pragma Singleton
import Quickshell
import QtQuick

// Region picker state. The overlay lives in modules/capture/RegionSelector.qml.
Singleton {
    id: root
    property bool active: false
    signal chosen(string geometry)     // "x,y wxh" in screen coordinates
    signal canceled()

    function begin() { active = true }
    function cancel() { if (!active) return; active = false; canceled() }
    function finish(g) { active = false; pending = g; settle.restart() }
    property string pending: ""
    Timer { id: settle; interval: 220; onTriggered: root.chosen(root.pending) }
}

import Quickshell
import Quickshell.Io
import QtQuick

// One brightnessctl device. match = "" is the screen; "*kbd_backlight*" is the keyboard.
Scope {
    id: root
    property string match: ""
    property real minValue: 0.01
    property real value: 0
    property bool available: false
    property real _applied: -1
    readonly property var devArgs: match !== "" ? ["-d", match] : []

    function refresh() { get.command = ["brightnessctl", "-m"].concat(devArgs, ["info"]); get.running = true }
    function set(v) { value = Math.max(minValue, Math.min(1, v)); throttle.restart() }
    function apply() {
        if (setProc.running) return
        _applied = value
        setProc.command = ["brightnessctl"].concat(devArgs, ["set", Math.round(value * 100) + "%"])
        setProc.running = true
    }

    function nudge(pct) {
        nudgeProc.command = ["brightnessctl"].concat(devArgs, ["set", Math.abs(pct) + "%" + (pct > 0 ? "+" : "-")])
        nudgeProc.running = true
    }
    Process { id: nudgeProc; onExited: root.refresh() }
    Timer { id: throttle; interval: 50; onTriggered: root.apply() }
    Process {
        id: get
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 4) { root.value = parseInt(p[3]) / 100; root.available = true }
                else root.available = false
            }
        }
    }
    Process {
        id: setProc
        onExited: if (Math.abs(root._applied - root.value) > 0.001) root.apply()
    }
}

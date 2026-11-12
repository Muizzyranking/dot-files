pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Reads values from the live config and writes changes to config.json. The file is watched,
// so a saved change applies to the running shell immediately.
Singleton {
    id: root
    property var pendingObj: null
    property string pendingText: ""

    function get(path) {
        let t = Config.v
        for (const k of path) { if (t === undefined || t === null) return undefined; t = t[k] }
        return t
    }
    function clone(o) { return JSON.parse(JSON.stringify(o)) }

    // Sets one value (creating the section if needed) and saves shortly after.
    // Several quick changes are combined into one write.
    function setPath(path, value) {
        const o = pendingObj !== null ? pendingObj : clone(Config.raw)
        let t = o
        for (let i = 0; i < path.length - 1; i++) {
            const k = path[i]
            if (typeof t[k] !== "object" || t[k] === null || Array.isArray(t[k])) t[k] = {}
            t = t[k]
        }
        t[path[path.length - 1]] = value
        pendingObj = o
        pendingText = JSON.stringify(o, null, 2) + "\n"
        debounce.restart()
        stale.restart()
    }

    // Values with a fixed set of choices
    readonly property var enums: ({
        "workspaces.label": ["index", "name"],
        "lock.clockStyle": ["stacked", "inline"],
        "eyes.mood": ["auto", "neutral", "happy", "playful", "sleepy", "moody", "tired", "sad", "angry", "scared"],
        "toasts.monitor": ["focused", "primary", "all"],
        "monitors.tray": ["all", "primary"],
        "wallpaper.fit": ["crop", "fit", "stretch"],
        "widgets.clock.monitors": ["all", "primary"],
        "widgets.clock.position": ["top-left", "top-center", "top-right", "center-left", "center", "center-right", "bottom-left", "bottom-center", "bottom-right"]
    })
    function options(path) {
        const key = path.join(".")
        if (key === "palette") return Theming.names
        return enums[key] ?? null
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            writer.command = ["sh", "-c", 'printf "%s" "$2" > "$1"', "_", Quickshell.shellPath("config.json"), root.pendingText]
            writer.running = true
        }
    }
    Timer { id: stale; interval: 1500; onTriggered: root.pendingObj = null }
    Process { id: writer }
}

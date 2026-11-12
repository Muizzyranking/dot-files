pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Launcher state and launch counts (most used apps come first). Counts are kept in
// ~/.local/state/qs-shell/launch-counts.json
Singleton {
    id: root
    property bool open: false
    property string screenName: ""
    property var counts: ({})
    readonly property string file: Quickshell.env("HOME") + "/.local/state/qs-shell/launch-counts.json"

    function toggle() { if (open) open = false; else show() }
    function show() { screenName = Hypr.focusedScreen(); open = true }
    function hide() { open = false }
    function record(id) {
        const c = Object.assign({}, counts)
        c[id] = (c[id] || 0) + 1
        counts = c
        save.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "_", file, JSON.stringify(c)]
        save.running = true
    }

    FileView { id: cf; path: root.file; blockLoading: true; printErrors: false }
    Component.onCompleted: { try { counts = JSON.parse(cf.text() || "{}") } catch (e) {} }
    Process { id: save }
}

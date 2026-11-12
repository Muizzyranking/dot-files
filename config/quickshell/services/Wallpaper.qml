pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Wallpaper list and the current choice (remembered between restarts).
Singleton {
    id: root
    property var list: []
    property string current: ""
    readonly property string home: Quickshell.env("HOME")
    readonly property string stateFile: home + "/.local/state/qs-shell/wallpaper"
    readonly property string folder: Config.v.wallpaper.dir.replace(/^~/, home)

    function refresh() { scan.running = true }
    function set(p) {
        current = p
        save.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "_", stateFile, p]
        save.running = true
    }
    function step(d) {
        if (list.length === 0) return
        const i = list.indexOf(current)
        set(list[((i < 0 ? 0 : i) + d + list.length) % list.length])
    }
    function random() {
        if (list.length < 2) return
        let p = current
        while (p === current) p = list[Math.floor(Math.random() * list.length)]
        set(p)
    }

    FileView { id: st; path: root.stateFile; blockLoading: true; printErrors: false }
    Component.onCompleted: {
        current = (st.text() || "").trim() || Config.v.wallpaper.default.replace(/^~/, home)
        refresh()
    }

    Process {
        id: scan
        command: ["sh", "-c",
            'find "$1" -maxdepth 3 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \\) 2>/dev/null | sort',
            "_", root.folder]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(x => x !== "")
                if (root.current === "" && root.list.length > 0) root.current = root.list[0]
            }
        }
    }
    Process { id: save }
    Timer {
        running: Config.v.wallpaper.intervalMin > 0 && root.list.length > 1
        repeat: true
        interval: Math.max(1, Config.v.wallpaper.intervalMin) * 60000
        onTriggered: Config.v.wallpaper.random ? root.random() : root.step(1)
    }
}

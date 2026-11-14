pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Lists of things installed on the system (fonts, cursor themes, icon themes, GTK themes).
// Each list is read once, the first time a setting asks for it.
Singleton {
    id: root
    property var fonts: []
    property var cursors: []
    property var icons: []
    property var gtk: []
    property var asked: ({})

    function ensure(kind) {
        if (!kind || asked[kind]) return
        asked[kind] = true
        if (kind === "font") pf.running = true
        else if (kind === "cursor") pc.running = true
        else if (kind === "icons") pi.running = true
        else if (kind === "gtk") pg.running = true
    }
    function lines(t) { return t.split("\n").filter(x => x !== "") }

    readonly property string iconDirs: '"$HOME/.icons" "$HOME/.local/share/icons" /usr/share/icons /usr/local/share/icons'
    Process {
        id: pf
        command: ["sh", "-c", "fc-list : family | sed 's/,.*//' | sort -u"]
        stdout: StdioCollector { onStreamFinished: root.fonts = root.lines(text) }
    }
    Process {
        id: pc
        command: ["sh", "-c", "for d in " + root.iconDirs + "; do for t in \"$d\"/*/; do [ -d \"${t}cursors\" ] && basename \"$t\"; done; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: root.cursors = root.lines(text) }
    }
    Process {
        id: pi
        command: ["sh", "-c", "for d in " + root.iconDirs + "; do for t in \"$d\"/*/; do [ -f \"${t}index.theme\" ] && grep -q '^Directories=' \"${t}index.theme\" && basename \"$t\"; done; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: root.icons = root.lines(text) }
    }
    Process {
        id: pg
        command: ["sh", "-c", "for d in /usr/share/themes \"$HOME/.themes\" \"$HOME/.local/share/themes\"; do for t in \"$d\"/*/; do [ -d \"${t}gtk-3.0\" ] || [ -d \"${t}gtk-4.0\" ] && basename \"$t\"; done; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: root.gtk = root.lines(text) }
    }
}

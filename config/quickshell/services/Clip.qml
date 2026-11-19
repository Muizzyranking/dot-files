pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Clipboard history through cliphist, plus pins. A pinned entry is copied out of
// cliphist into the shell's state directory, so "clear" (cliphist wipe) keeps it.
Singleton {
    id: root

    property var items: []          // { id, text, mime } from cliphist
    property var pins: []           // { key, text, mime } stored under pinDir

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/qs-shell/clipboard"
    readonly property string pinDir: dir + "/pins"
    readonly property string manifest: dir + "/pins.json"

    Component.onCompleted: {
        ensureDir.running = true
        const raw = pinsFile.text() || ""
        let parsed = []
        try {
            parsed = raw !== "" ? JSON.parse(raw) : []
        } catch (e) {
            parsed = []
        }
        root.pins = parsed
    }

    function refresh() { list.running = true }
    function copy(id) {
        act.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", String(id)]
        act.running = true
    }
    function remove(id) {
        act.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "_", String(id)]
        act.running = true
    }
    function wipe() { act.command = ["cliphist", "wipe"]; act.running = true }

    // Pins
    function pinKey(text) {
        const hit = root.pins.find(p => p.text === text)
        return hit ? hit.key : ""
    }
    function togglePin(item) {
        const key = root.pinKey(item.text)
        if (key !== "") {
            unpin(key)
            return
        }
        const newKey = "p" + Date.now()
        pinProc.command = ["sh", "-c", 'mkdir -p "$1" && cliphist decode "$2" > "$1/$3"', "_", root.pinDir, String(item.id), newKey]
        pinProc.running = true
        root.pins = root.pins.concat([{ key: newKey, text: item.text, mime: item.mime || "text/plain" }])
        writePins()
    }
    function unpin(key) {
        root.pins = root.pins.filter(p => p.key !== key)
        writePins()
        act.command = ["sh", "-c", 'rm -f "$1"', "_", root.pinDir + "/" + key]
        act.running = true
    }
    // Clear only the pins; the history in cliphist is untouched.
    function clearPins() {
        root.pins = []
        writePins()
        act.command = ["sh", "-c", 'rm -f "$1"/*', "_", root.pinDir]
        act.running = true
    }
    function copyPin(pin) {
        const file = root.pinDir + "/" + pin.key
        if (String(pin.mime).indexOf("image/") === 0) {
            act.command = ["sh", "-c", 'wl-copy --type "$1" < "$2"', "_", pin.mime, file]
        } else {
            act.command = ["sh", "-c", 'wl-copy < "$1"', "_", file]
        }
        act.running = true
    }
    function writePins() {
        pinsFile.setText(JSON.stringify(root.pins))
    }

    Process {
        id: list
        // No cap: the whole history is listed. The ListView only builds visible rows.
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const m = line.match(/^(\d+)\t(.*)$/)
                    if (!m) continue
                    const bin = m[2].match(/^\[\[ binary data \S+ \S+ (\w+)/)
                    out.push({ id: m[1], text: m[2].slice(0, 160), mime: bin ? "image/" + bin[1] : "" })
                }
                root.items = out
            }
        }
    }
    Process { id: act; onExited: root.refresh() }
    Process { id: pinProc }
    Process { id: ensureDir; command: ["mkdir", "-p", root.pinDir] }

    FileView {
        id: pinsFile
        path: root.manifest
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        printErrors: false
    }

    Process { running: Config.v.clipboard.manageWatcher; command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"] }
    Process { running: Config.v.clipboard.manageWatcher; command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"] }
}

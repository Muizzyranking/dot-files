pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Clipboard history through cliphist. It needs something storing entries:
// or set "clipboard.manageWatcher": true to let the shell run them.
Singleton {
    id: root
    property var items: []          // { id, text }

    function refresh() { list.running = true }
    function copy(id) { act.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", String(id)]; act.running = true }
    function remove(id) { act.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "_", String(id)]; act.running = true }
    function wipe() { act.command = ["cliphist", "wipe"]; act.running = true }

    Process {
        id: list
        command: ["sh", "-c", "cliphist list | head -n " + Config.v.clipboard.maxItems]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const m = line.match(/^(\d+)\t(.*)$/)
                    if (m) out.push({ id: m[1], text: m[2].slice(0, 160) })
                }
                root.items = out
            }
        }
    }
    Process { id: act; onExited: root.refresh() }

    Process { running: Config.v.clipboard.manageWatcher; command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"] }
    Process { running: Config.v.clipboard.manageWatcher; command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"] }
}

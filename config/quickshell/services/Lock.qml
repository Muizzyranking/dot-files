pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick
import qs.core

// Lock state and password check (PAM).
Singleton {
    id: root
    property bool locked: false
    property string password: ""
    property string error: ""
    property bool busy: false
    property int failed: 0

    // A flag file remembers that we were locked. If the shell restarts or crashes while
    // locked, it locks again at start so you can still enter your password.
    readonly property string flag: Quickshell.env("HOME") + "/.local/state/qs-shell/locked"
    function mark(on) {
        flagProc.command = ["sh", "-c", on ? 'mkdir -p "$(dirname "$1")" && printf 1 > "$1"' : 'rm -f "$1"', "_", flag]
        flagProc.running = true
    }
    FileView { id: ff; path: root.flag; blockLoading: true; printErrors: false }
    Process { id: flagProc }
    Component.onCompleted: { if (Config.v.lock.restoreOnStart && (ff.text() || "").trim() !== "") locked = true }

    function lock() {
        if (locked) return
        password = ""; error = ""; busy = false
        mark(true)
        locked = true
    }
    function unlock() { locked = false; password = ""; error = ""; busy = false; mark(false) }
    function submit() {
        if (busy || password === "") return
        busy = true
        error = ""
        pam.start()
    }

    PamContext {
        id: pam
        config: Config.v.lock.pamConfig
        onPamMessage: { if (responseRequired) respond(root.password) }
        onCompleted: result => {
            root.busy = false
            if (result === PamResult.Success) root.unlock()
            else { root.error = "Wrong password"; root.password = ""; root.failed++ }
        }
        onError: err => { root.busy = false; root.error = "Could not check the password"; root.password = "" }
    }
}

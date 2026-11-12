pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

Singleton {
    function run(cmd) {
        if (!cmd) return
        proc.command = ["sh", "-c", cmd]
        proc.running = true
    }
    function lock() {
        if (Config.v.session.lock) run(Config.v.session.lock)
        else Lock.lock()
    }
    Process { id: proc }
}

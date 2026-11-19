pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

Singleton {
    // Sleep has to happen *after* the lock screen is on screen. If the machine
    // freezes while the lock surface is still being built, the compositor keeps
    // showing the old frame on wake for several seconds, and typing does nothing
    // until it is replaced.
    property string sleepCmd: ""
    property bool externalLock: false
    property double waitStart: 0

    function run(cmd) {
        if (!cmd) return
        proc.command = ["sh", "-c", cmd]
        proc.running = true
    }
    function lock() {
        if (Config.v.session.lock) run(Config.v.session.lock)
        else Lock.lock()
    }
    // Lock, wait for the surface to show (or for a foreign locker, wait a
    // little), then run the sleep command. Already locked: go straight there.
    function sleep(cmd) {
        if (!cmd) return
        if (Lock.locked) { run(cmd); return; }
        sleepCmd = cmd
        externalLock = Config.v.session.lock !== ""
        waitStart = Date.now()
        if (externalLock) run(Config.v.session.lock)
        else Lock.lock()
        waitTimer.start()
    }
    function checkSleep() {
        if (sleepCmd === "") { waitTimer.stop(); return }
        const elapsed = Date.now() - waitStart
        const ready = externalLock ? elapsed >= 900 : (Lock.surfacesDrawn && elapsed >= 300)
        if (!ready && elapsed < 2000) return
        waitTimer.stop()
        const cmd = sleepCmd
        sleepCmd = ""
        run(cmd)
    }

    Timer {
        id: waitTimer
        interval: 50
        repeat: true
        onTriggered: Session.checkSleep()
    }
    Process { id: proc }
}

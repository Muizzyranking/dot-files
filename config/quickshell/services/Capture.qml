pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Screenshots (grim) and screen recording (wf-recorder). Regions are picked with the
// built-in selector (no slurp needed). Needs: grim, wl-clipboard, wf-recorder
// libnotify, and satty for annotation.
Singleton {
    id: root
    readonly property bool recording: recorder.running
    property int elapsed: 0
    property string _kind: ""
    property string _mode: ""
    property string _screen: ""
    property string _geom: ""

    function dir(p) { return p.replace(/^~/, Quickshell.env("HOME")) }
    function screenshot(mode, scr, now) { _kind = "shot"; _mode = mode; _screen = scr || ""; now ? go() : delay.restart() }
    function record(mode, scr, now) { if (recording) return; _kind = "rec"; _mode = mode; _screen = scr || ""; now ? go() : delay.restart() }
    function toggleRecord(scr) { if (recording) stop(); else record("screen", scr, true) }
    function stop() { Selector.cancel(); stopper.running = true }

    function go() {
        if (_mode === "region" || _mode === "annotate") Selector.begin()
        else if (_kind === "shot") runShot()
        else runRec()
    }
    Connections {
        target: Selector
        function onChosen(g) { root._geom = g; if (root._kind === "shot") root.runShot(); else root.runRec() }
    }

    function runShot() {
        const pre = 'mkdir -p "$1"; f="$1/screenshot-$(date +%F_%H-%M-%S).png"; '
        const done = ' && wl-copy < "$f" && notify-send -i "$f" "Screenshot saved" "$f"'
        let s
        if (_mode === "region") s = pre + 'grim -g "$3" "$f"' + done
        else if (_mode === "annotate") s = pre + 'grim -g "$3" - | ' + Config.v.capture.annotate
        else s = pre + 'if [ -n "$2" ]; then grim -o "$2" "$f"; else grim "$f"; fi' + done
        shot.command = ["sh", "-c", s, "_", dir(Config.v.capture.screenshotDir), _screen, _geom]
        shot.running = true
    }
    function runRec() {
        if (recorder.running) return
        const pre = 'mkdir -p "$1"; f="$1/recording-$(date +%F_%H-%M-%S).mp4"; '
        const au = 'ar=; if [ -n "$4" ]; then if [ "$4" = default ]; then ar=-a; else ar="--audio=$4"; fi; fi; '
        const post = '; notify-send "Recording saved" "$f"'
        const s = _mode === "region"
            ? pre + au + 'wf-recorder $ar -g "$3" -f "$f"' + post
            : pre + au + 'wf-recorder $ar -o "$2" -f "$f"' + post
        recorder.command = ["sh", "-c", s, "_", dir(Config.v.capture.recordDir), _screen, _geom, Config.v.capture.audio]
        elapsed = 0
        recorder.running = true
    }

    Timer { id: delay; interval: 450; onTriggered: root.go() }
    Process { id: shot }
    Process { id: recorder }
    Process { id: stopper; command: ["sh", "-c", "pkill -INT wf-recorder"] }
    Timer { running: recorder.running; repeat: true; interval: 1000; onTriggered: root.elapsed++ }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Antigravity AI provider. Tracks live CLI agent state, telemetry,
// conversation resumption, and notifies strictly when a task is finished or input is needed.
Singleton {
    id: root

    readonly property string name: "Antigravity"
    readonly property string icon: "smart_toy"
    property bool ready: false
    property bool running: false
    property bool busy: false
    property int attention: 0
    property double lastActivity: 0

    property string conversationId: ""
    property string model: "Gemini"
    property int stepIndex: 0
    property double turnStartMs: 0
    property double elapsedMs: 0
    property int inputTokens: 0
    property int outputTokens: 0
    property int cacheReadTokens: 0
    property string lastPrompt: ""
    property var requests: []
    property var sessions: []

    // Live timer while agent is busy
    property double liveElapsedMs: elapsedMs
    readonly property bool notifyOnDone: Config.v.ai && Config.v.ai.notifyOnDone !== undefined ? Config.v.ai.notifyOnDone : true

    // Tracks step index to prevent duplicate or intermediate notifications
    property int lastNotifiedStep: -1

    onBusyChanged: {
        if (busy) {
            liveElapsedMs = 0
            liveTimer.restart()
        } else {
            liveTimer.stop()
        }
    }

    Timer {
        id: liveTimer
        interval: 1000
        repeat: true
        running: root.busy
        onTriggered: {
            root.liveElapsedMs += 1000
        }
    }

    function fmtDuration(ms) {
        const totalSecs = Math.max(0, Math.round(ms / 1000))
        const mins = Math.floor(totalSecs / 60)
        const secs = totalSecs % 60
        if (mins > 0) {
            return mins + "m " + secs + "s"
        }
        return secs + "s"
    }

    function notifyFinished(durMs) {
        if (!notifyOnDone) {
            return
        }
        notifyProc.command = [
            "notify-send",
            "-a", "Antigravity",
            "-i", "smart_toy",
            "Antigravity AI",
            "Task finished (" + fmtDuration(durMs) + ")"
        ]
        notifyProc.running = true
    }

    function notifyActionNeeded() {
        if (!notifyOnDone) {
            return
        }
        notifyProc.command = [
            "notify-send",
            "-a", "Antigravity",
            "-u", "critical",
            "-i", "help",
            "Antigravity AI",
            "Action required: Waiting for your input"
        ]
        notifyProc.running = true
    }

    Process {
        id: notifyProc
    }

    function copyCommand(id) {
        const target = id ? id : conversationId
        if (target) {
            copyProc.command = ["wl-copy", "agy --conversation " + target]
            copyProc.running = true
        }
    }

    Process {
        id: copyProc
    }

    function removeSession(id) {
        const target = id ? id : conversationId
        if (target) {
            rmProc.command = ["rm", "-rf", Quickshell.env("HOME") + "/.gemini/antigravity-cli/brain/" + target]
            rmProc.running = true
        }
    }

    Process {
        id: rmProc
        onExited: root.poll()
    }

    function poll() {
        if (!statusProc.running) {
            statusProc.running = true
        }
    }

    Process {
        id: statusProc
        command: ["python3", Quickshell.shellPath("extras/agy-status.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.applyStatus(text)
            }
        }
    }

    function parse(t) {
        try {
            return JSON.parse(t)
        } catch (e) {
            return null
        }
    }

    function applyStatus(txt) {
        const o = parse(txt)
        if (!o) {
            return
        }

        const prevStep = root.stepIndex
        root.ready = o.ready ? true : false
        root.running = o.running ? true : false
        root.busy = o.busy ? true : false
        root.attention = o.attention ? o.attention : 0
        root.conversationId = o.conversationId ? o.conversationId : ""
        root.model = o.model ? o.model : "Gemini"
        root.stepIndex = o.stepIndex ? o.stepIndex : 0
        root.turnStartMs = o.turnStartMs ? o.turnStartMs : 0
        root.elapsedMs = o.elapsedMs ? o.elapsedMs : 0
        root.lastActivity = o.lastActivity ? o.lastActivity : Date.now()
        root.inputTokens = o.inputTokens ? o.inputTokens : 0
        root.outputTokens = o.outputTokens ? o.outputTokens : 0
        root.cacheReadTokens = o.cacheReadTokens ? o.cacheReadTokens : 0
        root.lastPrompt = o.lastPrompt ? o.lastPrompt : ""
        root.sessions = o.sessions ? o.sessions : []

        if (!root.busy) {
            root.liveElapsedMs = root.elapsedMs
        }

        // On first run, baseline the step so we don't notify for previous tasks
        if (root.lastNotifiedStep === -1) {
            root.lastNotifiedStep = root.stepIndex
            return
        }

        // Check strictly for task finished or action needed on NEW steps
        if (root.stepIndex > root.lastNotifiedStep) {
            if (o.actionNeeded) {
                root.lastNotifiedStep = root.stepIndex
                root.notifyActionNeeded()
            } else if (o.taskFinished) {
                root.lastNotifiedStep = root.stepIndex
                root.notifyFinished(root.elapsedMs)
            }
        }
    }

    Component.onCompleted: {
        root.poll()
    }
}

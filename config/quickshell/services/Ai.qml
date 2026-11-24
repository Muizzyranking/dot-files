pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Aggregates AI providers and owns the suspend inhibitor: while armed
// (ai.suspendInhibit), a logind sleep:idle lock is held exactly while some
// provider is busy, so the machine never suspends mid-agent.
Singleton {
    id: root

    // Register new providers here. Each one is a singleton exposing:
    //   ready (bool, service reachable), busy (bool, a turn is running),
    //   attention (int, pending prompts that need the user),
    //   sessions (list, for the panel) and action functions.
    readonly property var providers: [AiAntigravity, AiOpencode]

    readonly property bool running: providers.some(p => p.ready)
    readonly property bool busy: providers.some(p => p.busy)
    readonly property int attention: providers.reduce((n, p) => n + p.attention, 0)
    readonly property bool inhibitArmed: Config.v.ai.suspendInhibit
    readonly property bool inhibit: inhibitArmed && busy

    property int tick: 0
    readonly property double lastActivity: providers.reduce((m, p) => Math.max(m, p.lastActivity ?? 0), 0)
    readonly property string mood: {
        const _ = tick
        if (attention > 0) return "waiting"
        if (busy) return "thinking"
        if (!running) return "off"
        return Date.now() - lastActivity > Config.v.ai.sleepyAfterMs ? "sleepy" : "neutral"
    }
    Timer {
        interval: 30000
        running: root.running
        repeat: true
        onTriggered: root.tick++
    }

    Timer {
        interval: root.inhibitArmed ? 2000 : 5000
        running: root.running
        repeat: true
        onTriggered: root.pollProviders()
    }

    function pollProviders() {
        for (const p of root.providers) {
            p.poll()
        }
    }

    Process {
        command: ["systemd-inhibit", "--what=sleep:idle", "--who=qs-ai", "--why=AI agents running", "sleep", "infinity"]
        running: root.inhibit
    }
}

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
    readonly property var providers: [AiOpencode]

    readonly property bool running: providers.some(p => p.ready)
    readonly property bool busy: providers.some(p => p.busy)
    readonly property int attention: providers.reduce((n, p) => n + p.attention, 0)
    readonly property bool inhibitArmed: Config.v.ai.suspendInhibit
    readonly property bool inhibit: inhibitArmed && busy

    Process {
        // Quickshell terminates child processes on exit, so the lock cannot
        // outlive the shell.
        command: ["systemd-inhibit", "--what=sleep:idle", "--who=qs-ai", "--why=AI agents running", "sleep", "infinity"]
        running: root.inhibit
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Static system info plus uptime. Refreshed by the control center while it is open.
Singleton {
    id: root
    property string os: ""
    property string kernel: ""
    property string host: ""
    property string cpu: ""
    property real uptimeSec: 0
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP") || ""

    function refresh() { proc.running = true }
    function fmtUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d > 0 ? d + "d " : "") + (h > 0 || d > 0 ? h + "h " : "") + m + "m"
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "grep -m1 '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '\"'; " +
            "cat /proc/sys/kernel/osrelease; cat /proc/sys/kernel/hostname; " +
            "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2; cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                root.os = (l[0] || "").trim()
                root.kernel = (l[1] || "").trim()
                root.host = (l[2] || "").trim()
                root.cpu = (l[3] || "").trim().replace(/\s+/g, " ")
                root.uptimeSec = parseFloat(l[4]) || 0
            }
        }
    }
}

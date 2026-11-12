pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

Singleton {
    id: root
    property real memory: 0      // percent used
    property real swap: 0
    property real cpu: 0
    property real disk: 0
    property real memUsedKb: 0
    property real memTotalKb: 0
    property real swapUsedKb: 0
    property real swapTotalKb: 0
    property real diskUsedB: 0
    property real diskTotalB: 0
    property int cores: 1
    property real _idle: 0
    property real _total: 0

    // Full process list, only polled while the vitals panel is open
    property bool watchProcs: false
    property var procs: []           // { pid, name, user, kb, cpu }
    property var _psRows: []

    function parseMem(t) {
        const g = k => { const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")); return m ? +m[1] : 0 }
        const total = g("MemTotal"), avail = g("MemAvailable")
        memTotalKb = total
        memUsedKb = total - avail
        memory = total > 0 ? (total - avail) / total * 100 : 0
        const st = g("SwapTotal"), sf = g("SwapFree")
        swapTotalKb = st
        swapUsedKb = st - sf
        swap = st > 0 ? (st - sf) / st * 100 : 0
    }
    function parseCpu(t) {
        const f = t.split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + (f[4] || 0)
        const total = f.reduce((a, b) => a + b, 0)
        if (_total > 0) {
            const dt = total - _total, di = idle - _idle
            cpu = dt > 0 ? Math.max(0, Math.min(100, (1 - di / dt) * 100)) : 0
        }
        _total = total
        _idle = idle
    }
    function parseDf(t) {
        const m = t.match(/(\d+)\s+(\d+)\s+(\d+)%/)
        if (m) { diskUsedB = +m[1]; diskTotalB = +m[2]; disk = +m[3] }
    }

    FileView { id: memFile; path: "/proc/meminfo"; onLoaded: root.parseMem(text()) }
    FileView { id: cpuFile; path: "/proc/stat"; onLoaded: root.parseCpu(text()) }
    Timer {
        running: true; repeat: true; triggeredOnStart: true
        interval: Config.v.vitals.intervalMs
        onTriggered: { memFile.reload(); cpuFile.reload() }
    }
    Process {
        id: df
        command: ["df", "-B1", "--output=used,size,pcent", "/"]
        stdout: StdioCollector { onStreamFinished: root.parseDf(text) }
    }
    Timer {
        running: true; repeat: true; triggeredOnStart: true
        interval: Config.v.vitals.diskIntervalMs
        onTriggered: df.running = true
    }

    function parsePs(t) {
        const rows = []
        for (const line of t.split("\n")) {
            const m = line.match(/^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*\S)\s*$/)
            if (m && m[4] !== "ps" && m[4] !== "top") rows.push({ pid: +m[1], kb: +m[2], user: m[3], name: m[4] })
        }
        _psRows = rows
    }
    function parseTop(t) {
        const lines = t.split("\n")
        const c = lines.find(l => l.startsWith("cores:"))
        if (c) cores = parseInt(c.slice(6)) || 1
        let start = 0
        lines.forEach((l, i) => { if (l.startsWith("top -")) start = i })
        const cpuBy = {}
        let rows = false
        for (let i = start; i < lines.length; i++) {
            const l = lines[i].trim()
            if (l.startsWith("PID")) { rows = true; continue }
            if (!rows || !l) continue
            const f = l.split(/\s+/)
            const v = parseFloat((f[8] || "").replace(",", "."))
            if (!isNaN(v)) cpuBy[f[0]] = v / cores
        }
        procs = _psRows.map(p => ({ pid: p.pid, name: p.name, user: p.user, kb: p.kb, cpu: cpuBy[p.pid] || 0 }))
    }
    function kill(pid, force) {
        killer.command = ["kill", force ? "-KILL" : "-TERM", String(pid)]
        killer.running = true
        killRefresh.restart()
    }

    Process {
        id: psProc
        command: ["ps", "-eo", "pid=,rss=,user=,comm="]
        stdout: StdioCollector { onStreamFinished: root.parsePs(text) }
    }
    Process {
        id: topProc
        command: ["sh", "-c", "echo cores:$(nproc); top -b -n 2 -d 0.5 -w 200"]
        stdout: StdioCollector { onStreamFinished: root.parseTop(text) }
    }
    Process { id: killer }
    Timer { id: killRefresh; interval: 600; onTriggered: { psProc.running = true; topProc.running = true } }
    Timer {
        running: root.watchProcs; repeat: true; triggeredOnStart: true
        interval: 2500
        onTriggered: { psProc.running = true; topProc.running = true }
    }
}

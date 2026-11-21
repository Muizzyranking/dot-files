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

    // Process list, only polled while the vitals panel is open.
    // Rows are grouped by executable name, one entry per app.
    property bool watchProcs: false
    property var procs: []           // { name, user, count, kb, rssKb, pssKb, cpu, pids, roots }
    property var _psRows: []
    property var _cpuBy: ({})
    property var _pssByPid: ({})
    property int _tick: 0

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

    // processes
    function parsePs(t) {
        const rows = []
        for (const line of t.split("\n")) {
            const m = line.match(/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.*\S)\s*$/)
            if (m && m[5] !== "ps" && m[5] !== "top" && m[5] !== "grep") {
                rows.push({ pid: +m[1], ppid: +m[2], kb: +m[3], user: m[4], name: m[5] })
            }
        }
        _psRows = rows
        buildGroups()
    }
    function parseTop(t) {
        const lines = t.split("\n")
        const c = lines.find(l => l.startsWith("cores:"))
        if (c) cores = parseInt(c.slice(6)) || 1
        let start = 0
        lines.forEach((l, i) => { if (l.startsWith("top -")) start = i })
        const cpuBy = {}
        let iPid = 0, iCpu = 8, rows = false
        for (let i = start; i < lines.length; i++) {
            const l = lines[i].trim()
            if (l.startsWith("PID")) {
                const names = l.split(/\s+/)
                iPid = Math.max(0, names.indexOf("PID"))
                iCpu = names.indexOf("%CPU")
                rows = iCpu >= 0
                continue
            }
            if (!rows || !l) continue
            const f = l.split(/\s+/)
            const v = parseFloat((f[iCpu] || "").replace(",", "."))
            if (!isNaN(v)) cpuBy[f[iPid]] = v / cores
        }
        _cpuBy = cpuBy
        buildGroups()
    }
    // PSS is the only memory number that can be summed across processes: RSS
    // counts every shared page once per process, so Chrome would look like it
    // uses twice its real memory. Root-owned processes cannot be read, so they
    // fall back to RSS below.
    function parsePss(t) {
        const map = {}
        for (const line of t.split("\n")) {
            const m = line.match(/^\/proc\/(\d+)\/smaps_rollup:Pss:\s+(\d+)/)
            if (m) map[+m[1]] = +m[2]
        }
        _pssByPid = map
        buildGroups()
    }
    function buildGroups() {
        if (_psRows.length === 0) return
        const nameByPid = {}
        for (const p of _psRows) nameByPid[p.pid] = p.name
        const groups = {}
        const order = []
        for (const p of _psRows) {
            const gk = "g_" + p.name
            let g = groups[gk]
            if (!g) {
                g = { name: p.name, user: p.user, count: 0, rssKb: 0, pssKb: 0, rssNoPssKb: 0, cpu: 0, pids: [], roots: [] }
                groups[gk] = g
                order.push(p.name)
            }
            const pss = _pssByPid[p.pid] || 0
            const cpu = _cpuBy[p.pid] || 0
            // Topmost process of its own name tree: Chrome's browser has the
            // same name as its zygotes/renderers, so "root" cannot just mean
            // "parent is not running".
            const isRoot = nameByPid[p.ppid] !== p.name
            g.count++
            g.rssKb += p.kb
            g.cpu += cpu
            if (pss > 0) {
                g.pssKb += pss
            } else {
                g.rssNoPssKb += p.kb
            }
            if (isRoot) g.roots.push(p.pid)
            g.pids.push({ pid: p.pid, ppid: p.ppid, kb: pss > 0 ? pss : p.kb, rssKb: p.kb, cpu: cpu, isRoot: isRoot })
        }
        const out = []
        for (const name of order) {
            const g = groups["g_" + name]
            out.push({
                name: g.name,
                user: g.user,
                count: g.count,
                kb: g.pssKb + g.rssNoPssKb,
                rssKb: g.rssKb,
                pssKb: g.pssKb,
                cpu: g.cpu,
                pids: g.pids,
                roots: g.roots
            })
        }
        procs = out
    }
    function kill(pid, force) {
        killer.command = ["kill", force ? "-KILL" : "-TERM", String(pid)]
        killer.running = true
        killRefresh.restart()
    }

    Process {
        id: psProc
        command: ["ps", "-eo", "pid=,ppid=,rss=,user=,comm="]
        stdout: StdioCollector { onStreamFinished: root.parsePs(text) }
    }
    Process {
        id: topProc
        command: ["sh", "-c", "echo cores:$(nproc); top -b -n 2 -d 0.5 -w 200"]
        stdout: StdioCollector { onStreamFinished: root.parseTop(text) }
    }
    // grep -s keeps going when a root-owned smaps_rollup is unreadable.
    Process {
        id: pssProc
        command: ["sh", "-c", "grep -sH '^Pss:' /proc/[0-9]*/smaps_rollup"]
        stdout: StdioCollector { onStreamFinished: root.parsePss(text) }
    }
    Process { id: killer }
    Timer { id: killRefresh; interval: 600; onTriggered: { psProc.running = true; topProc.running = true } }
    Timer {
        running: root.watchProcs; repeat: true; triggeredOnStart: true
        interval: 2500
        onTriggered: {
            root._tick++
            psProc.running = true
            topProc.running = true
            // PSS costs ~0.3s of reads, so refresh it every other tick.
            if (root._tick % 2 === 1) pssProc.running = true
        }
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// opencode provider. State comes from the background service's local HTTP
// API; discovery is XDG_STATE_HOME/opencode/service.json (url + basic-auth
// password, rewritten whenever the service restarts). The service's SSE
// stream turned out unreliable (silent connections, different vocabulary),
// so live state is polled by Ai.qml instead; lists also refresh whenever the
// panel opens (call refresh()).
Singleton {
    id: root

    readonly property bool running: baseUrl !== ""
    readonly property bool ready: running
    readonly property bool busy: {
        for (const k in activeMap) {
            const t = activeMap[k].type
            if (t === "busy" || t === "retry") return true
        }
        return false
    }
    readonly property int attention: requests.length
    property var sessions: []
    property var requests: []
    property double lastActivity: 0

    // internals
    property string baseUrl: ""
    property string auth: ""          // curl -u argument
    property var activeMap: ({})      // sessionID -> {type: busy|retry|idle}
    property var modelCtx: ({})       // "providerID/modelID" -> context limit
    property double busySince: 0

    onBusyChanged: {
        if (busy) {
            busySince = Date.now()
        } else {
            lastActivity = Date.now()
        }
    }

    function reset() {
        baseUrl = ""
        auth = ""
        activeMap = {}
        modelCtx = {}
        sessions = []
        requests = []
        lastSessionsJson = ""
        lastActiveJson = ""
    }

    function applyService(t) {
        const o = t ? parse(t) : null
        if (!o || !o.url || !o.password) {
            reset()
            return
        }
        baseUrl = o.url
        auth = "opencode:" + o.password
        refresh()
    }

    function parse(t) { try { return JSON.parse(t) } catch (e) { return null } }

    Timer {
        running: root.baseUrl === ""
        interval: 10000
        repeat: true
        onTriggered: svc.reload()
    }

    FileView {
        id: svc
        path: (Quickshell.env("XDG_STATE_HOME") ?? (Quickshell.env("HOME") + "/.local/state")) + "/opencode/service.json"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: root.applyService(text())
        onFileChanged: root.applyService(text())
    }

    property int pollCount: 0
    function poll() {
        if (baseUrl === "") {
            return
        }
        pollCount++
        refreshActive()
        refreshRequests()
        if (pollCount % 3 === 1) {
            refreshSessions()
        }
    }

    property int callIdx: 0
    property var callPool: [c0, c1, c2, c3]

    function call(method, path, body, cb) {
        if (baseUrl === "") {
            return
        }
        const cmd = ["curl", "-s", "-m", "10", "-u", auth, "-X", method, baseUrl + path]
        if (body) {
            cmd.push("-H", "Content-Type: application/json", "-d", JSON.stringify(body))
        }
        const p = callPool[callIdx % callPool.length]
        callIdx++
        p.cb = cb
        p.command = cmd
        p.running = true
    }

    // fixed instances so the pool can reference them directly
    Process { id: c0; property var cb: null; stdout: StdioCollector { onStreamFinished: root.callDone(c0, text) } }
    Process { id: c1; property var cb: null; stdout: StdioCollector { onStreamFinished: root.callDone(c1, text) } }
    Process { id: c2; property var cb: null; stdout: StdioCollector { onStreamFinished: root.callDone(c2, text) } }
    Process { id: c3; property var cb: null; stdout: StdioCollector { onStreamFinished: root.callDone(c3, text) } }

    function callDone(p, text) {
        const f = p.cb
        p.cb = null
        if (f) {
            f(parse(text))
        }
    }

    Timer { id: requestsSoon; interval: 250; onTriggered: root.refreshRequests() }

    // Reassign only on real changes: QML re-runs every binding on assignment,
    // so polling identical data would churn the pill and panel for nothing.
    property string lastSessionsJson: ""
    property string lastActiveJson: ""

    function refresh() {
        refreshSessions()
        refreshRequests()
        refreshModels()
    }

    function refreshSessions() {
        call("GET", "/api/session", null, d => {
            const list = d?.data ?? []
            // top-level only: subagents are transient, the parent represents them
            const top = list.filter(s => !s.parentID)
            top.sort((a, b) => (b.time?.updated ?? 0) - (a.time?.updated ?? 0))
            const cut = top.slice(0, 40)
            const j = JSON.stringify(cut)
            if (j !== lastSessionsJson) {
                lastSessionsJson = j
                sessions = cut
            }
            let newest = 0
            for (const s of top) {
                newest = Math.max(newest, s.time?.updated ?? 0)
            }
            if (newest > lastActivity) {
                lastActivity = newest
            }
        })
    }

    function refreshActive() {
        call("GET", "/api/session/active", null, d => {
            const a = d?.data ?? {}
            const m = {}
            for (const k in a) {
                m[k] = { type: normStatus(a[k]?.type) }
            }
            const j = JSON.stringify(m)
            if (j === lastActiveJson) {
                return
            }
            lastActiveJson = j
            activeMap = m
        })
    }

    function refreshRequests() {
        call("GET", "/api/permission/request", null, p => {
            call("GET", "/api/question/request", null, q => {
                const ps = (p?.data ?? []).map(r => ({
                    kind: "permission", id: r.id, sessionID: r.sessionID,
                    name: r.permission ?? "", metadata: r.metadata ?? {}
                }))
                const qs = (q?.data ?? []).map(r => ({
                    kind: "question", id: r.id, sessionID: r.sessionID,
                    questions: r.questions ?? []
                }))
                requests = ps.concat(qs)
            })
        })
    }

    // A notification for every prompt that appears (goes through this shell's
    // own notification server, so it lands in the panel and as a toast).
    property var notified: ({})
    onRequestsChanged: {
        const live = {}
        for (const r of requests) {
            live[r.id] = true
            if (notified[r.id]) continue
            notified[r.id] = true
            const s = sessions.find(x => x.id === r.sessionID)
            const about = s?.title ?? ""
            const isQuestion = r.kind === "question"
            const header = isQuestion ? (r.questions[0]?.header ?? r.questions[0]?.question ?? "Question") : r.name
            notify((isQuestion ? "opencode asks: " : "opencode needs approval: ") + header,
                about)
        }
        notified = live
    }

    function notify(summary, body) {
        notifProc.command = ["notify-send", "-a", "opencode", "-u", "normal", summary, body]
        notifProc.running = true
    }

    Process { id: notifProc }

    function refreshModels() {
        call("GET", "/api/model", null, d => {
                const m = {}
                for (const x of d?.data ?? []) {
                    if (x.limit?.context > 0) m[x.providerID + "/" + x.modelID] = x.limit.context
                }
                modelCtx = m
        })
    }

    // The REST active map says "running"; normalize so busy/retry mean "a turn
    // is running" everywhere.
    function normStatus(t) {
        return t === "running" || t === "busy" || t === "retry" ? (t === "retry" ? "retry" : "busy") : "idle"
    }

    function status(id) { return activeMap[id]?.type ?? "idle" }

    function contextPct(s) {
        const limit = modelCtx[(s.model?.providerID ?? "") + "/" + (s.model?.id ?? "")]
        const used = (s.tokens?.input ?? 0) + (s.tokens?.cache?.read ?? 0)
        if (!limit || !used) return -1
        return Math.round(used / limit * 100)
    }

    // actions
    function interrupt(sessionID) {
        call("POST", "/api/session/" + sessionID + "/interrupt", {}, () => refreshSessions())
    }

    // reply: "once" | "always" | "reject"
    function permissionReply(sessionID, requestID, reply) {
        call("POST", "/api/session/" + sessionID + "/permission/" + requestID + "/reply", { reply: reply }, () => requestsSoon.restart())
    }

    // answers: one array of selected labels per question
    function questionReply(sessionID, requestID, answers) {
        call("POST", "/api/session/" + sessionID + "/question/" + requestID + "/reply", { answers: answers }, () => requestsSoon.restart())
    }

    function questionReject(sessionID, requestID) {
        call("POST", "/api/session/" + sessionID + "/question/" + requestID + "/reject", {}, () => requestsSoon.restart())
    }

    // Permanently remove a session and its history.
    function removeSession(sessionID) {
        call("DELETE", "/api/session/" + sessionID, null, () => refreshSessions())
    }

    // Stop every busy session (including subagents).
    function stopAll() {
        let n = 0
        for (const k in activeMap) {
            const t = activeMap[k].type
            if (t === "busy" || t === "retry") { interrupt(k); n++ }
        }
        return n
    }

    // Copy the command that resumes a session in a terminal.
    function copyCommand(sessionID) {
        copyProc.command = ["sh", "-c", 'printf "%s" "$1" | wl-copy', "_", "opencode -s " + sessionID]
        copyProc.running = true
    }

    // Resume command of the newest session (pill right-click, IPC).
    function copyLatest() {
        const s = sessions[0]
        if (s) {
            copyCommand(s.id)
        }
    }

    Process { id: copyProc }
}

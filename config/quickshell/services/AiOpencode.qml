pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// opencode provider. State comes from the background service's local HTTP
// API; discovery is XDG_STATE_HOME/opencode/service.json (url + basic-auth
// password, rewritten whenever the service restarts). Live changes arrive on
// the service's SSE event stream; lists refresh debounced when relevant
// events fire and whenever the panel opens (call refresh()).
Singleton {
    id: root

    // --- provider interface (consumed by Ai.qml and the UI) ---
    readonly property bool running: baseUrl !== ""
    readonly property bool ready: running && streamUp
    readonly property bool busy: {
        for (const k in activeMap) {
            const t = activeMap[k].type
            if (t === "busy" || t === "retry") return true
        }
        return false
    }
    readonly property int attention: requests.length
    property var sessions: []   // top-level sessions, newest first, capped
    property var requests: []   // pending permission + question requests

    // --- internals ---
    property string baseUrl: ""
    property string auth: ""          // curl -u argument
    property string authHeader: ""    // "Basic ..." for XMLHttpRequest
    property var activeMap: ({})      // sessionID -> {type: busy|retry|idle}
    property var modelCtx: ({})       // "providerID/modelID" -> context limit
    property bool streamUp: false
    property double busySince: 0

    onBusyChanged: if (busy) busySince = Date.now()

    function b64(s) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        let out = ""
        for (let i = 0; i < s.length; i += 3) {
            const n = (s.charCodeAt(i) << 16) | ((s.charCodeAt(i + 1) ?? 0) << 8) | (s.charCodeAt(i + 2) ?? 0)
            out += chars[(n >> 18) & 63] + chars[(n >> 12) & 63]
            out += i + 1 < s.length ? chars[(n >> 6) & 63] : "="
            out += i + 2 < s.length ? chars[n & 63] : "="
        }
        return out
    }

    function reset() {
        baseUrl = ""
        auth = ""
        authHeader = ""
        streamUp = false
        activeMap = {}
        modelCtx = {}
        sessions = []
        requests = []
        stream.running = false
    }

    function applyService(t) {
        const o = t ? parse(t) : null
        if (!o || !o.url || !o.password) { reset(); return }
        baseUrl = o.url
        auth = "opencode:" + o.password
        authHeader = "Basic " + b64("opencode:" + o.password)
        startStream()
        refresh()
    }

    function parse(t) { try { return JSON.parse(t) } catch (e) { return null } }

    // --- transport: SSE stream (live) + one-shot requests (lists, actions) ---
    function startStream() {
        stream.running = false
        if (baseUrl === "") return
        stream.command = ["curl", "-sN", "-u", auth, baseUrl + "/api/event"]
        stream.running = true
    }

    Process {
        id: stream
        stdout: SplitParser {
            onRead: line => root.onEventLine(line)
        }
        onExited: {
            root.streamUp = false
            root.restartT.restart()   // service may just be busy; retry shortly
        }
    }
    Timer {
        id: restartT
        interval: 3000
        onTriggered: root.startStream()
    }
    // the service may start later than the shell; re-check discovery lightly
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

    function onEventLine(line) {
        if (!line.startsWith("data: ")) return
        const e = parse(line.slice(6))
        if (!e || !e.type) return
        const t = e.type
        if (t === "server.connected") { streamUp = true; refresh() }
        else if (t === "session.status") {
            const d = e.data ?? e.properties ?? {}
            if (d.sessionID && d.status) activeMap[d.sessionID] = { type: normStatus(d.status.type) }
            sessionsSoon.restart()
        }
        else if (t === "session.idle") {
            const d = e.data ?? e.properties ?? {}
            if (d.sessionID) activeMap[d.sessionID] = { type: "idle" }
            sessionsSoon.restart()
        }
        else if (t.startsWith("permission.") || t.startsWith("question.")) requestsSoon.restart()
        else if (t.startsWith("message.")) sessionsSoon.restart()
    }

    function call(method, path, body, cb) {
        if (baseUrl === "") return
        const x = new XMLHttpRequest()
        x.open(method, baseUrl + path, true)
        x.setRequestHeader("Authorization", authHeader)
        x.onreadystatechange = function () {
            if (x.readyState !== 4) return
            let d = null
            try { d = x.responseText ? JSON.parse(x.responseText) : null } catch (e) {}
            if (cb) cb(d)
        }
        if (body) {
            x.setRequestHeader("Content-Type", "application/json")
            x.send(JSON.stringify(body))
        } else x.send()
    }

    // --- refresh (debounced) ---
    Timer { id: sessionsSoon; interval: 400; onTriggered: root.refreshSessions() }
    Timer { id: requestsSoon; interval: 250; onTriggered: root.refreshRequests() }

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
            sessions = top.slice(0, 40)
        })
        call("GET", "/api/session/active", null, d => {
            const a = d?.data ?? {}
            const m = {}
            for (const k in a) m[k] = { type: normStatus(a[k]?.type) }
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

    function refreshModels() {
        call("GET", "/api/model", null, d => {
            const m = {}
            for (const x of d?.data ?? []) {
                if (x.limit?.context > 0) m[x.providerID + "/" + x.modelID] = x.limit.context
            }
            modelCtx = m
        })
    }

    // The REST active map says "running"; SSE events say "busy". Normalize so
    // busy/retry mean "a turn is running" everywhere.
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

    // --- actions ---
    function interrupt(sessionID) {
        call("POST", "/api/session/" + sessionID + "/interrupt", {}, () => refreshSessions())
    }

    // reply: "once" | "always" | "reject"
    function permissionReply(sessionID, requestID, reply) {
        call("POST", "/api/session/" + sessionID + "/permission/" + requestID + "/reply", { reply }, () => requestsSoon.restart())
    }

    // answers: one array of selected labels per question
    function questionReply(sessionID, requestID, answers) {
        call("POST", "/api/session/" + sessionID + "/question/" + requestID + "/reply", { answers }, () => requestsSoon.restart())
    }

    function questionReject(sessionID, requestID) {
        call("POST", "/api/session/" + sessionID + "/question/" + requestID + "/reject", {}, () => requestsSoon.restart())
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

    // Focus the window running the opencode TUI (walks from the TUI process
    // up to its terminal window, then dispatches a Hyprland focus).
    function reveal() {
        revealProc.running = true
    }

    Process {
        id: revealProc
        command: ["sh", "-c",
            "p=$(pgrep -x opencode | while read q; do grep -qa ' serve' /proc/$q/cmdline || echo \"$q\"; done | head -1)\n" +
            "[ -n \"$p\" ] || exit 0\n" +
            "c=$(hyprctl clients -j | jq -r '.[] | \"\\(.pid) \\(.address)\"')\n" +
            "while [ \"$p\" -gt 1 ]; do\n" +
            "  a=$(printf '%s\\n' \"$c\" | awk -v p=\"$p\" '$1 == p { print $2 }')\n" +
            "  [ -n \"$a\" ] && { echo \"$a\"; exit 0; }\n" +
            "  p=$(awk '/^PPid:/{print $2}' /proc/$p/status)\n" +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const addr = text.trim().split("\n")[0]
                if (addr) Hypr.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })', "focuswindow address:" + addr)
            }
        }
    }
}

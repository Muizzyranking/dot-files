pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// NetworkManager through nmcli.
Singleton {
    id: root
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property bool ethernet: false
    property string ssid: ""
    property int signal: 0
    property var networks: []
    property var saved: []
    property string pending: ""
    property string error: ""
    property var ipInfo: ({})

    readonly property string icon: ethernet && !wifiConnected ? "lan"
        : !wifiEnabled ? "wifi_off"
        : !wifiConnected ? "wifi_find"
        : signal < 34 ? "wifi_1_bar" : signal < 67 ? "wifi_2_bar" : "wifi"

    function signalIcon(s) { return s < 34 ? "wifi_1_bar" : s < 67 ? "wifi_2_bar" : "wifi" }

    function refresh() { proc.running = true; listProc.running = true; savedProc.running = true }
    function scan() { rescan.running = true }
    function run(cmd) { act.command = cmd; act.running = true }
    function setEnabled(on) { run(["nmcli", "radio", "wifi", on ? "on" : "off"]) }
    function forget(name) { run(["nmcli", "connection", "delete", "id", name]) }
    function loadInfo() { infoProc.running = true }
    function disconnect() { run(["nmcli", "connection", "down", "id", ssid]) }
    function connectTo(name, pw) {
        pending = name
        error = ""
        run(pw ? ["nmcli", "dev", "wifi", "connect", name, "password", pw]
               : ["nmcli", "dev", "wifi", "connect", name])
    }

    function parse(t) {
        let en = false, wc = false, eth = false, name = "", sig = 0
        for (const line of t.split("\n")) {
            const p = line.split(":")
            if (p[0] === "radio") en = p[1] === "enabled"
            else if (p[0] === "dev") {
                if (p[1] === "wifi" && p[2] === "connected") { wc = true; name = p[3] || "" }
                if (p[1] === "ethernet" && p[2] === "connected") eth = true
            } else if (p[0] === "sig") sig = parseInt(p[2]) || 0
        }
        wifiEnabled = en; wifiConnected = wc; ethernet = eth; ssid = name; signal = sig
    }
    function parseList(t) {
        const best = {}
        for (const line of t.split("\n")) {
            if (!line) continue
            const p = line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"))
            const name = p[1]
            if (!name) continue
            const n = { ssid: name, active: p[0] === "*", signal: parseInt(p[2]) || 0, secure: !!p[3] && p[3] !== "--", security: p[3] || "", chan: p[4] || "", freq: p[5] || "", rate: p[6] || "", bssid: p[7] || "" }
            const o = best[name]
            if (!o || n.active || (!o.active && n.signal > o.signal)) best[name] = n
        }
        networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
    }
    function parseSaved(t) {
        saved = t.split("\n").filter(l => l.includes("wireless")).map(l => l.split(":")[0])
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "echo radio:$(nmcli radio wifi); " +
            "nmcli -t -f TYPE,STATE,CONNECTION device | sed 's/^/dev:/'; " +
            "nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\\*' | sed 's/^/sig:/'"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,CHAN,FREQ,RATE,BSSID", "dev", "wifi", "list"]
        stdout: StdioCollector { onStreamFinished: root.parseList(text) }
    }
    Process {
        id: infoProc
        command: ["sh", "-c", "d=$(nmcli -t -f DEVICE,TYPE device | grep ':wifi$' | head -1 | cut -d: -f1); nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show \"$d\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf(":")
                    if (i < 0) continue
                    const k = line.slice(0, i).replace(/\[\d+\]/, ""), v = line.slice(i + 1)
                    if (!o[k]) o[k] = v
                }
                root.ipInfo = { ip: o["IP4.ADDRESS"] || "", gateway: o["IP4.GATEWAY"] || "", dns: o["IP4.DNS"] || "" }
            }
        }
    }
    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector { onStreamFinished: root.parseSaved(text) }
    }
    Process {
        id: rescan
        command: ["nmcli", "dev", "wifi", "rescan"]
        onExited: root.refresh()
    }
    Process {
        id: act
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: { root.pending = ""; root.refresh() }
    }
    Timer {
        running: true; repeat: true; triggeredOnStart: true
        interval: Config.v.network.intervalMs
        onTriggered: proc.running = true
    }
}

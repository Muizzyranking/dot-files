pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev ? dev.isPresent : false
    // UPower reports 0..1; the guard also tolerates 0..100
    readonly property int percent: {
        const p = dev ? dev.percentage : 0
        return Math.round(p > 1 ? p : p * 100)
    }
    readonly property bool plugged: dev
        ? (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged)
        : false

    // Health comes straight from sysfs (design capacity vs current full capacity)
    property real health: -1          // percent, -1 = unknown
    property int cycles: -1
    property real fullAmount: 0
    property real designAmount: 0
    property string unit: "Wh"
    property real drawW: 0
    property string tech: ""

    function refreshHealth() { hp.running = true }
    function parseHealth(t) {
        const m = {}
        for (const line of t.split("\n")) { const i = line.indexOf("="); if (i > 0) m[line.slice(0, i)] = line.slice(i + 1).trim() }
        const full = parseFloat(m.full), design = parseFloat(m.design)
        const wh = m.unit === "Wh"
        fullAmount = isNaN(full) ? 0 : full / (wh ? 1e6 : 1e3)
        designAmount = isNaN(design) ? 0 : design / (wh ? 1e6 : 1e3)
        unit = wh ? "Wh" : "mAh"
        health = (full > 0 && design > 0) ? Math.min(100, full / design * 100) : -1
        cycles = m.cycles !== undefined && m.cycles !== "" ? parseInt(m.cycles) : -1
        const pw = parseFloat(m.power)
        drawW = isNaN(pw) ? 0 : pw / 1e6
        tech = m.tech || ""
    }

    Process {
        id: hp
        command: ["sh", "-c",
            "for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; " +
            "r() { cat \"$b/$1\" 2>/dev/null; }; " +
            "ef=$(r energy_full); ed=$(r energy_full_design); u=Wh; " +
            "if [ -z \"$ef\" ]; then ef=$(r charge_full); ed=$(r charge_full_design); u=mAh; fi; " +
            "echo full=$ef; echo design=$ed; echo unit=$u; echo cycles=$(r cycle_count); " +
            "echo tech=$(r technology); echo power=$(r power_now); break; done"]
        stdout: StdioCollector { onStreamFinished: root.parseHealth(text) }
    }
}

pragma Singleton
import Quickshell
import QtQuick
import qs.core

// Decides the eyes' mood from time, day, battery, CPU and memory, and the network.
// Priority (first match wins):
//   high CPU and memory   -> angry (scared if the battery is low too)
//   a single value maxed  -> scared
//   low battery           -> tired at night, sad by day
//   medium-low battery    -> moody
//   offline               -> moody
//   weekend night         -> playful
//   night                 -> sleepy
//   day, good battery     -> happy
// Test any mood with: qsctl mood set angry (qsctl mood auto to go back)
Singleton {
    id: root
    property string override: ""
    property string current: "neutral"
    property string _cand: ""
    property int _n: 0
    property bool _first: true
    readonly property var cfg: Config.v.eyes

    SystemClock { id: clk; precision: SystemClock.Minutes }

    function isNight(h) {
        return cfg.nightStart > cfg.nightEnd ? (h >= cfg.nightStart || h < cfg.nightEnd)
                                             : (h >= cfg.nightStart && h < cfg.nightEnd)
    }
    function candidate() {
        const d = clk.date, h = d.getHours(), wd = d.getDay()
        const night = isNight(h)
        const weekend = wd === 0 || wd === 6 || (wd === 5 && h >= cfg.nightStart)
        const hasBat = Battery.present
        const low = hasBat && !Battery.plugged && Battery.percent <= Config.v.battery.low
        const medLow = hasBat && !Battery.plugged && Battery.percent <= cfg.moodyBattery
        const good = !hasBat || Battery.plugged || Battery.percent >= cfg.happyBattery
        if (SysStats.cpu >= cfg.cpuHigh && SysStats.memory >= cfg.memHigh) return low ? "scared" : "angry"
        if (SysStats.cpu >= cfg.panic || SysStats.memory >= cfg.panic) return "scared"
        if (low) return night ? "tired" : "sad"
        if (medLow) return "moody"
        if (cfg.offlineMoody && !(Net.wifiConnected || Net.ethernet)) return "moody"
        if (weekend && night) return "playful"
        if (night) return "sleepy"
        if (good) return "happy"
        return "neutral"
    }
    function evaluate() {
        const c = override !== "" ? override : (cfg.mood !== "auto" ? cfg.mood : candidate())
        if (c === current) { _n = 0; _cand = c; return }
        if (c === _cand) _n++; else { _cand = c; _n = 1 }
        // a mood has to hold for a couple of samples, so it does not flicker
        if (_first || override !== "" || _n >= cfg.stableSamples) { current = c; _n = 0; _first = false }
    }
    function set(name) { override = name; evaluate() }
    function auto() { override = ""; evaluate() }

    Timer {
        running: true; repeat: true; triggeredOnStart: true
        interval: Math.max(1000, root.cfg.moodIntervalMs)
        onTriggered: root.evaluate()
    }
}

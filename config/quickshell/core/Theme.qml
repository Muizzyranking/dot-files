pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property real scale: Config.v.scale ?? 1.0
    function px(n) { return Math.round(n * scale) }

    readonly property string fontFamily: Config.v.font.family
    readonly property string iconFamily: Config.v.font.iconFamily
    readonly property int fontSize: px(Config.v.font.size)
    readonly property int iconSize: px(Config.v.font.iconSize)

    readonly property color barBg: Config.v.colors.barBg
    readonly property color panel: Config.v.colors.panel
    readonly property color surface: Config.v.colors.surface
    readonly property color surfaceHi: Config.v.colors.surfaceHi
    readonly property color island: Config.v.colors.island
    readonly property color islandText: Config.v.colors.onIsland
    readonly property color islandTextDim: Qt.alpha(Config.v.colors.onIsland, 0.65)
    readonly property color warm: Config.v.colors.warm
    readonly property color text: Config.v.colors.text
    readonly property color textDim: Config.v.colors.textDim
    readonly property color textFaint: Config.v.colors.textFaint
    readonly property color accent: Config.v.colors.accent
    readonly property color accentText: Config.v.colors.onAccent
    readonly property color good: Config.v.colors.good
    readonly property color warn: Config.v.colors.warn
    readonly property color bad: Config.v.colors.bad
    readonly property color info: Config.v.colors.info

    // A colour name from "colors" (like "warn") or any colour value
    function resolve(c) { return Qt.color(Config.v.colors[c] ?? c) }

    // Blends through the colour stops in config.json "vitals.stops"
    function vitalColor(pct) {
        const s = Config.v.vitals.stops
        const p = Math.max(0, Math.min(100, pct))
        for (let i = 1; i < s.length; i++) {
            if (p <= s[i][0]) {
                const a = resolve(s[i - 1][1]), b = resolve(s[i][1])
                const t = (p - s[i - 1][0]) / (s[i][0] - s[i - 1][0])
                return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
            }
        }
        return resolve(s[s.length - 1][1])
    }
}

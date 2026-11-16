pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Palettes and exporting them to other apps.
//  - palettes: list of palettes (name, preview colours, file defaults) for the pickers
//  - Switching palette also switches the wallpaper (wallpaper.followPalette) and, through
//    theming.system, the cursor, when the palette (or config.json "palettes") names them.
//  - apply(): when theming.enabled, renders templates/* into the paths in theming.targets and
//    runs a target's reload command ONLY if its file really changed. Also runs
//    extras/system-theme.sh (GTK, cursor, Qt) when theming.system.enabled.
//  - Changes are coalesced (several quick switches become one apply), and everything runs at
//    low priority so the desktop does not stall.
//  - At start, target files that do not exist yet are created.
//  - A target that is a symlink is replaced by a real file. A target path may contain *.
Singleton {
    id: root
    property var palettes: []
    readonly property var names: palettes.map(p => p.name)
    readonly property string current: Config.v.palette ?? ""
    property string lastPalette: ""
    property string lastWall: ""
    property string lastColors: ""
    property string lastSys: ""
    property string lastThemeSys: ""
    property bool ready: false
    property bool sysAfterRender: false

    function expand(p) { return String(p || "").replace(/^~/, Quickshell.env("HOME")) }
    function set(name) {
        if (!/^[A-Za-z0-9_-]+$/.test(name)) return
        write.command = ["sh", "-c",
            'f="$1"; s=$(sed "s/\\"palette\\": *\\"[^\\"]*\\"/\\"palette\\": \\"$2\\"/" "$f") && printf "%s\\n" "$s" > "$f"',
            "_", Quickshell.shellPath("config.json"), name]
        write.running = true
    }
    function next() {
        if (names.length === 0) return
        set(names[(names.indexOf(current) + 1) % names.length])
    }

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function cursorName() {
        const s = Config.v.theming.system
        if (s.cursor !== "auto") return s.cursor
        return Config.v.paletteSystem.cursor || s.cursorFallback || ""
    }
    function iconName() {
        const s = Config.v.theming.system
        if (s.icons !== "auto") return s.icons
        return Config.v.paletteSystem.icons || s.iconsFallback || ""
    }
    function hex(c) { return String(c).replace("#", "").slice(-6) }
    function rgb(c) { const k = Qt.color(c); return Math.round(k.r * 255) + ", " + Math.round(k.g * 255) + ", " + Math.round(k.b * 255) }
    function mix(a, b, t) {
        const x = Qt.color(a), y = Qt.color(b)
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0")
        return "#" + h(x.r + (y.r - x.r) * t) + h(x.g + (y.g - x.g) * t) + h(x.b + (y.b - x.b) * t)
    }
    function hueDist(a, b) {
        const ha = Qt.color(a).hsvHue, hb = Qt.color(b).hsvHue
        if (ha < 0 || hb < 0) return 0
        const d = Math.abs(ha - hb)
        return Math.min(d, 1 - d)
    }

    // Every {{token}} a template can use (each also as {{token.hex}} and {{token.rgb}})
    function tokens() {
        const c = Config.v.colors
        const k = Qt.color(c.barBg)
        const dark = (0.2126 * k.r + 0.7152 * k.g + 0.0722 * k.b) < 0.5
        const m = {
            bg: c.barBg, panel: c.panel, surface: c.surface, surfaceHi: c.surfaceHi, island: c.island,
            fg: c.text, fgDim: c.textDim, fgFaint: c.textFaint, accent: c.accent, onAccent: c.onAccent,
            good: c.good, warn: c.warn, warm: c.warm, bad: c.bad, info: c.info,
            blue: c.blue, purple: c.purple, magenta: c.magenta, cyan: c.cyan, foam: c.foam,
            redAlt: c.redAlt ?? mix(c.bad, "#000000", 0.25),
            fgBright: mix(c.text, dark ? "#ffffff" : "#000000", 0.3),
            diffAdd: mix(c.barBg, c.good, 0.22), diffChange: mix(c.barBg, c.blue, 0.2),
            diffDelete: mix(c.barBg, c.bad, 0.22), diffText: mix(c.barBg, c.blue, 0.38)
        }
        let best = c.info, bd = -1
        for (const cand of [c.info, c.magenta, c.cyan, c.good, c.blue, c.purple]) {
            const d = hueDist(c.accent, cand)
            if (d > bd) { bd = d; best = cand }
        }
        m.contrast = best
        return { map: m, mode: dark ? "dark" : "light" }
    }

    // One target. The file is only written (and its app reloaded) when the new content differs.
    function targetScript(tg, expr, missingOnly, home, reload) {
        const tpl = q(Quickshell.shellPath("templates/" + tg.template))
        const out = tg.out.replace(/^~/, home)
        const segs = out.split("/")
        const gi = segs.findIndex(s => s.indexOf("*") >= 0)
        let body = "chg=0\n"
        if (gi < 0) body += "o=" + q(out) + "\n"
        else body += "for b in " + segs.slice(0, gi + 1).join("/") + "; do [ -d \"$b\" ] || continue\no=\"$b\"/" + q(segs.slice(gi + 1).join("/")) + "\n"
        if (missingOnly)
            body += "[ -e \"$o\" ] || { mkdir -p \"$(dirname \"$o\")\" && sed -e " + q(expr) + " " + tpl + " > \"$o\"; }\n"
        else
            body += "t=$(mktemp) && sed -e " + q(expr) + " " + tpl + " > \"$t\" && { " +
                "if [ -f \"$o\" ] && [ ! -L \"$o\" ] && cmp -s \"$t\" \"$o\"; then :; " +
                "else [ -L \"$o\" ] && rm -f \"$o\"; mkdir -p \"$(dirname \"$o\")\" && cat \"$t\" > \"$o\"; chg=1; fi; }; rm -f \"$t\"\n"
        if (gi >= 0) body += "done\n"
        // every reload runs under timeout: a hanging app
        // must never leave the render process stuck, or future applies stop silently
        if (!missingOnly && reload) body += '[ "$chg" = 1 ] && { timeout 10 sh -c ' + q(reload) + '; } >/dev/null 2>&1\n'
        return body
    }

    // missingOnly = true creates only the files that do not exist yet.
    // A render takes up to ~10s (app reload timeouts), so an apply arriving while
    property int pendingApply: -1
    property bool pendingSys: false
    function apply(missingOnly) {
        if (render.running) { pendingApply = missingOnly ? 1 : 0; return }
        const t = tokens()
        const home = Quickshell.env("HOME")
        const parts = []
        for (const k in t.map) {
            const v = t.map[k]
            parts.push("s|{{" + k + "}}|" + v + "|g", "s|{{" + k + "\\.hex}}|" + hex(v) + "|g", "s|{{" + k + "\\.rgb}}|" + rgb(v) + "|g")
        }
        parts.push("s|{{name}}|" + current + "|g", "s|{{mode}}|" + t.mode + "|g",
            "s|{{cursor}}|" + cursorName() + "|g", "s|{{cursorSize}}|" + Config.v.theming.system.cursorSize + "|g")
        const expr = parts.join(";")
        let sh = ""
        for (const tg of Config.v.theming.targets)
            sh += targetScript(tg, expr, missingOnly, home, tg.reload ? tg.reload.replace(/\{\{mode\}\}/g, t.mode).replace(/\{\{gtk\}\}/g, t.mode === "dark" ? Config.v.theming.system.gtkThemeDark : Config.v.theming.system.gtkTheme) : "")
        // the system script runs after the render: it assembles the GTK theme from
        // the freshly rendered colours file, so it must not race the render
        sysAfterRender = true
        if (sh !== "") { render.command = ["nice", "-n", "10", "sh", "-c", sh]; render.running = true }
        else { sysAfterRender = false; applySystem() }    }

    // GTK settings, GTK/Qt preferences and the cursor (extras/system-theme.sh)
    function applySystem() {
        if (sys.running) { pendingSys = true; return }
        const s = Config.v.theming.system
        if (!s.enabled) return
        const t = tokens()
        sys.environment = {
            "SHELL_MODE": t.mode,
            "SHELL_GTK_THEME": t.mode === "dark" ? s.gtkThemeDark : s.gtkTheme,
            "SHELL_ICONS": iconName(),
            "SHELL_CURSOR": cursorName(),
            "SHELL_CURSOR_SIZE": String(s.cursorSize),
            "SHELL_FONT": s.font,
            "SHELL_QT": s.qt ? "1" : "",
            "SHELL_GTK_CLEAN": s.cleanGtk ? "1" : "",
            "SHELL_QT_COLORS": Quickshell.env("HOME") + "/.config/qt6ct/colors/shell.conf"
        }
        sys.command = ["nice", "-n", "10", "sh", Quickshell.shellPath("extras/system-theme.sh")]
        sys.running = true
    }

    function snapshot() {
        lastPalette = Config.v.palette ?? ""
        lastWall = expand(Config.v.paletteSystem.wallpaper)
        lastColors = JSON.stringify(Config.v.colors)
        lastSys = JSON.stringify(Config.v.paletteSystem)
        lastThemeSys = JSON.stringify(Config.v.theming.system)
    }

    Connections {
        target: Config
        function onVChanged() {
            if (!root.ready) return
            const pal = Config.v.palette ?? ""
            const wall = root.expand(Config.v.paletteSystem.wallpaper)
            const colors = JSON.stringify(Config.v.colors)
            const sys = JSON.stringify(Config.v.paletteSystem)
            const themeSys = JSON.stringify(Config.v.theming.system)
            if (Config.v.wallpaper.followPalette !== false && wall !== "" && (pal !== root.lastPalette || wall !== root.lastWall))
                Wallpaper.set(wall)
            const colorsChanged = colors !== root.lastColors, sysChanged = sys !== root.lastSys
            const themeSysChanged = themeSys !== root.lastThemeSys
            root.lastPalette = pal; root.lastWall = wall; root.lastColors = colors
            root.lastSys = sys; root.lastThemeSys = themeSys
            if (!Config.v.theming.enabled) return
            if (colorsChanged) applyT.restart()
            else if (sysChanged || themeSysChanged) sysT.restart()
        }
    }
    Timer { id: applyT; interval: 600; onTriggered: root.apply(false) }
    Timer { id: sysT; interval: 600; onTriggered: root.applySystem() }
    Timer {
        running: true; interval: 2500
        onTriggered: {
            root.snapshot()
            root.ready = true
            if (Config.v.theming.enabled) { root.apply(false) }
        }
    }

    Process {
        id: render
        // the system script needs the rendered colours file, so it waits for this
        onExited: {
            if (root.pendingApply >= 0) { const m = root.pendingApply; root.pendingApply = -1; root.apply(m === 1); return }
            if (!root.sysAfterRender) return
            root.sysAfterRender = false
            root.applySystem()
        }
    }

    Process {
        command: ["sh", "-c",
            'for f in "$1"/*.json; do [ -f "$f" ] || continue; n=$(basename "$f" .json); ' +
            'g() { sed -n "s/.*\\"$1\\": *\\"\\([^\\"]*\\)\\".*/\\1/p" "$f" | head -1; }; ' +
            'printf "%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n" "$n" "$(g accent)" "$(g barBg)" "$(g text)" "$(g cursor)" "$(g wallpaper)" "$(g icons)"; done',
            "_", Quickshell.shellPath("palettes")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.palettes = text.split("\n").filter(l => l.trim() !== "").map(l => {
                const p = l.split("\t")
                return { name: p[0], accent: p[1] || "#888888", bg: p[2] || "#222222", text: p[3] || "#dddddd", cursor: p[4] || "", wallpaper: p[5] || "", icons: p[6] || "" }
            })
        }
    }
    Process { id: write }
    Process {
        id: sys
        onExited: {
            if (!root.pendingSys) return
            root.pendingSys = false
            root.applySystem()
        }
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// Palettes and exporting them to other apps.
//  - palettes: list of palettes (name + preview colours) for the control center picker
//  - apply(): when theming.enabled, renders templates/* into the paths in theming.targets
//    and runs each target's reload command. Also runs extras/theme.sh (GTK, cursor,
//    Qt) when theming.system.enabled.
//  - At start, target files that do not exist yet are created.
//  - A target that is a symlink is replaced by a real file, so a downloaded theme is
//    never modified. A target path may contain * (for example a Firefox profile folder).
Singleton {
    id: root
    property var palettes: []
    readonly property var names: palettes.map(p => p.name)
    readonly property string current: Config.v.palette ?? ""
    property string lastSig: ""
    property bool ready: false

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
        // a colour far from the accent, so "active" and "inactive" never look alike
        let best = c.info, bd = -1
        for (const cand of [c.info, c.magenta, c.cyan, c.good, c.blue, c.purple]) {
            const d = hueDist(c.accent, cand)
            if (d > bd) { bd = d; best = cand }
        }
        m.contrast = best
        return { map: m, mode: dark ? "dark" : "light" }
    }

    function targetScript(tg, expr, missingOnly, home, reload) {
        const tpl = q(Quickshell.shellPath("templates/" + tg.template))
        const out = tg.out.replace(/^~/, home)
        const segs = out.split("/")
        const gi = segs.findIndex(s => s.indexOf("*") >= 0)
        const write = o => "mkdir -p \"$(dirname " + o + ")\" && sed -e " + q(expr) + " " + tpl + " > " + o
        let body
        if (gi < 0) body = "o=" + q(out) + "\n"
        else body = "for b in " + segs.slice(0, gi + 1).join("/") + "; do [ -d \"$b\" ] || continue\no=\"$b\"/" + q(segs.slice(gi + 1).join("/")) + "\n"
        body += missingOnly ? "[ -e \"$o\" ] || { " + write("\"$o\"") + "; }\n"
                            : "[ -L \"$o\" ] && rm -f \"$o\"\n" + write("\"$o\"") + "\n"
        if (gi >= 0) body += "done\n"
        if (!missingOnly && reload) body += reload + " >/dev/null 2>&1 || true\n"
        return body
    }

    // missingOnly = true creates only the files that do not exist yet
    function apply(missingOnly) {
        const t = tokens()
        const home = Quickshell.env("HOME")
        const parts = []
        for (const k in t.map) {
            const v = t.map[k]
            parts.push("s|{{" + k + "}}|" + v + "|g", "s|{{" + k + "\\.hex}}|" + hex(v) + "|g", "s|{{" + k + "\\.rgb}}|" + rgb(v) + "|g")
        }
        parts.push("s|{{name}}|" + current + "|g", "s|{{mode}}|" + t.mode + "|g")
        const expr = parts.join(";")
        let sh = ""
        for (const tg of Config.v.theming.targets)
            sh += targetScript(tg, expr, missingOnly, home, tg.reload ? tg.reload.replace(/\{\{mode\}\}/g, t.mode) : "")
        if (sh !== "") { render.command = ["sh", "-c", sh]; render.running = true }
        applySystem()
    }

    // GTK settings, GTK/Qt preferences and the cursor (extras/theme.sh)
    function applySystem() {
        const s = Config.v.theming.system
        if (!s.enabled) return
        const t = tokens()
        const cursor = s.cursor === "auto" ? (Config.v.paletteSystem.cursor ?? "") : s.cursor
        sys.environment = {
            "SHELL_MODE": t.mode,
            "SHELL_GTK_THEME": t.mode === "dark" ? s.gtkThemeDark : s.gtkTheme,
            "SHELL_ICONS": s.icons,
            "SHELL_CURSOR": cursor,
            "SHELL_CURSOR_SIZE": String(s.cursorSize),
            "SHELL_FONT": s.font,
            "SHELL_QT": s.qt ? "1" : "",
            "SHELL_GTK_CLEAN": s.cleanGtk ? "1" : "",
            "SHELL_QT_COLORS": Quickshell.env("HOME") + "/.config/qt6ct/colors/shell.conf"
        }
        sys.command = ["sh", Quickshell.shellPath("extras/theme.sh")]
        sys.running = true
    }

    Connections {
        target: Config
        function onVChanged() {
            const sig = JSON.stringify([Config.v.colors, Config.v.paletteSystem])
            if (!root.ready) { root.lastSig = sig; return }
            if (sig !== root.lastSig) { root.lastSig = sig; if (Config.v.theming.enabled) root.apply(false) }
        }
    }
    Timer {
        running: true; interval: 2500
        onTriggered: {
            root.lastSig = JSON.stringify([Config.v.colors, Config.v.paletteSystem])
            root.ready = true
            if (Config.v.theming.enabled) { root.apply(true); root.applySystem() }
        }
    }

    Process {
        command: ["sh", "-c",
            'for f in "$1"/*.json; do [ -f "$f" ] || continue; n=$(basename "$f" .json); ' +
            'g() { sed -n "s/.*\\"$1\\": *\\"\\(#[^\\"]*\\)\\".*/\\1/p" "$f" | head -1; }; ' +
            'echo "$n $(g accent) $(g barBg) $(g text)"; done',
            "_", Quickshell.shellPath("palettes")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.palettes = text.split("\n").filter(l => l.trim() !== "").map(l => {
                const p = l.trim().split(/\s+/)
                return { name: p[0], accent: p[1] || "#888888", bg: p[2] || "#222222", text: p[3] || "#dddddd" }
            })
        }
    }
    Process { id: write }
    Process { id: render }
    Process { id: sys }
}

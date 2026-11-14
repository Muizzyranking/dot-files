pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.core

// The settings window's brain. It knows what each key MEANS (a font, a folder, an opacity, a
// colour name, ...) so the window can show the right control, and it writes changes to
// config.json (the file is watched, so every change applies to the running shell at once).
Singleton {
    id: root
    property var pendingObj: null
    property string pendingText: ""
    signal choiceRequested(var spec)
    signal colorRequested(var spec)
    signal fileRequested(var spec)

    function get(path) {
        let t = Config.v
        for (const k of path) { if (t === undefined || t === null) return undefined; t = t[k] }
        return t
    }
    function clone(o) { return JSON.parse(JSON.stringify(o)) }

    // Sets one value (creating the section if needed) and saves shortly after.
    // Several quick changes are combined into one write.
    function setPath(path, value) {
        const o = pendingObj !== null ? pendingObj : clone(Config.raw)
        let t = o
        for (let i = 0; i < path.length - 1; i++) {
            const k = path[i]
            if (typeof t[k] !== "object" || t[k] === null || Array.isArray(t[k])) t[k] = {}
            t = t[k]
        }
        t[path[path.length - 1]] = value
        pendingObj = o
        pendingText = JSON.stringify(o, null, 2) + "\n"
        debounce.restart()
        stale.restart()
    }

    // dialogs (shown by the settings window)
    function choose(spec) { choiceRequested(spec) }
    function pickColor(spec) { colorRequested(spec) }
    function pickPath(spec) { fileRequested(spec) }

    // ---- what each key is ----
    readonly property var enums: ({
        "workspaces.label": ["index", "name"],
        "eyes.mood": ["auto", "neutral", "happy", "playful", "sleepy", "moody", "tired", "sad", "angry", "scared"],
        "toasts.monitor": ["focused", "primary", "all"],
        "monitors.tray": ["all", "primary"],
        "wallpaper.fit": ["crop", "fit", "stretch"],
        "widgets.clock.monitors": ["all", "primary"],
        "widgets.clock.position": ["top-left", "top-center", "top-right", "center-left", "center", "center-right", "bottom-left", "bottom-center", "bottom-right"]
    })
    function options(path) {
        const key = path.join(".")
        if (key === "palette") return Theming.names
        return enums[key] ?? null
    }

    // first match wins. kind: choice | slider | image | dir | color | monitors
    readonly property var schema: [
        { re: /^font\.(family|iconFamily)$/, kind: "choice", choices: "font" },
        { re: /^font\.(size|iconSize)$/, kind: "slider", min: 8, max: 28, step: 1 },
        { re: /^scale$/, kind: "slider", min: 0.6, max: 2, step: 0.05 },
        { re: /(^|\.)(opacity|borderOpacity)$/i, kind: "slider", min: 0, max: 1, step: 0.01 },
        { re: /^(lock\.(blur|dim)|launcher\.dim)$/, kind: "slider", min: 0, max: 1, step: 0.01 },
        { re: /(^|\.)radius$/i, kind: "slider", min: 0, max: 48, step: 1 },
        { re: /^bar\.(marginX|marginY)$/, kind: "slider", min: 0, max: 60, step: 1 },
        { re: /^bar\.height$/, kind: "slider", min: 24, max: 80, step: 1 },
        { re: /^(wallpaper\.dir|capture\.(screenshotDir|recordDir))$/, kind: "dir", empty: false },
        { re: /^(wallpaper\.default|lock\.wallpaper|profile\.avatar)$/, kind: "image", empty: true },
        { re: /^palettes\.[^.]+\.wallpaper$/, kind: "image", empty: true, emptyLabel: "Leave unchanged" },
        { re: /^palettes\.[^.]+\.cursor$/, kind: "choice", choices: "cursor", empty: true, emptyLabel: "Leave unchanged" },
        { re: /^theming\.system\.cursor$/, kind: "choice", choices: "cursor", extra: ["auto"], empty: true, emptyLabel: "Leave unchanged" },
        { re: /^theming\.system\.icons$/, kind: "choice", choices: "icons", empty: true, emptyLabel: "Leave unchanged" },
        { re: /^theming\.system\.(gtkTheme|gtkThemeDark)$/, kind: "choice", choices: "gtk" },
        { re: /^monitors\.(include|exclude)$/, kind: "monitors" },
        { re: /^monitors\.primary$/, kind: "choice", choices: "monitor", empty: true, emptyLabel: "First monitor" },
        { re: /^(island\.(color|borderColor)|eyes\.color|panels\.borderColor|workspaces\.attentionColor|widgets\.clock\.color|lock\.clockColor|eyes\.moodColors\..+)$/, kind: "choice", choices: "colorname" },
        { re: /^colors\./, kind: "color" }
    ]
    function describe(path, value) {
        const key = path.join(".")
        for (const s of schema) if (s.re.test(key)) return s
        const t = typeof value
        if (t === "boolean") return { kind: "bool" }
        if (t === "number") return { kind: "num" }
        if (t === "string") {
            const o = options(path)
            if (!o) return { kind: "str" }
            return o.length > 6 ? { kind: "choice", choices: "list", list: o } : { kind: "enum" }
        }
        if (Array.isArray(value)) return value.every(x => typeof x === "string" || typeof x === "number") ? { kind: "list" } : { kind: "json" }
        return { kind: "json" }
    }
    // the list a "choice" setting picks from
    function choices(spec) {
        let base
        switch (spec.choices) {
            case "font": base = Installed.fonts; break
            case "cursor": base = Installed.cursors; break
            case "icons": base = Installed.icons; break
            case "gtk": base = Installed.gtk; break
            case "colorname": base = Object.keys(Config.v.colors); break
            case "monitor": base = Array.from(Quickshell.screens).map(s => s.name); break
            default: base = spec.list ?? []
        }
        return (spec.extra ?? []).concat(base)
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            writer.command = ["sh", "-c", 'printf "%s" "$2" > "$1"', "_", Quickshell.shellPath("config.json"), root.pendingText]
            writer.running = true
        }
    }
    Timer { id: stale; interval: 1500; onTriggered: root.pendingObj = null }
    Process { id: writer }
}

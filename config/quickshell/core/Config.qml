pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// config.json is the one file you edit. Saving it updates the shell live.
// "palette" picks palettes/<name>.json; anything in config.json "colors" overrides it.
// A syntax error keeps the last good values and prints a warning.
Singleton {
    id: root

    function parse(t) {
        try { return JSON.parse(t) } catch (e) { return null }
    }

    property var raw: parse(file.text()) ?? ({})
    readonly property string paletteName: raw.palette ?? ""
    readonly property var palette: paletteName !== "" ? (parse(paletteFile.text()) ?? ({})) : ({})

    // Defaults for sections added in later versions, so an older config.json keeps working
    readonly property var fallback: ({
        launcher: { columns: 7, iconSize: 64, cellWidth: 150, cellHeight: 120, dim: 0.9 },
        lock: { pamConfig: "login", wallpaper: "", blur: 0.7, dim: 0.35, timeFormat: "h:mm", dateFormat: "dddd, d MMMM", showMedia: true,
                clockStyle: "stacked", clockSize: 130, clockColor: "accent", hourFormat: "HH", minuteFormat: "mm", restoreOnStart: true },
        theming: {
            enabled: false, targets: [],
            system: { enabled: false, gtkTheme: "adw-gtk3", gtkThemeDark: "adw-gtk3-dark", icons: "Reversal-blue-dark", cursor: "auto", cursorSize: 24, font: "", qt: false, cleanGtk: true }
        },
        panels: { gap: 6, border: 1, borderOpacity: 0.12, borderColor: "text" },
        workspaces: { attention: true, attentionColor: "warm" },
        profile: { name: "", avatar: "" },
        session: { lock: "" },
        bar: { marginX: 0, marginY: 0, border: 0, borderOpacity: 0.1 },
        monitors: { include: [], exclude: [], primary: "", tray: "all" },
        toasts: { monitor: "focused" },
        island: { flare: 8 },
        widgets: { clock: { monitors: "all" } },
        eyes: {
            mood: "auto", moodIntervalMs: 5000, stableSamples: 2, nightStart: 22, nightEnd: 6,
            moodyBattery: 35, happyBattery: 60, cpuHigh: 85, memHigh: 85, panic: 95, offlineMoody: true,
            moodColors: { neutral: "onIsland", happy: "onIsland", playful: "accent", sleepy: "textDim", moody: "accent",
                          tired: "textDim", sad: "info", angry: "warm", scared: "onIsland" }
        }
    })
    function fill(dst, src) {
        for (const k in src) {
            if (dst[k] === undefined) dst[k] = src[k]
            else if (typeof src[k] === "object" && !Array.isArray(src[k]) && typeof dst[k] === "object") fill(dst[k], src[k])
        }
        return dst
    }

    // The merged result. Read values like Config.v.bar.height
    readonly property var v: {
        const o = JSON.parse(JSON.stringify(raw))
        // older configs had one "bar.margin"
        if (o.bar && o.bar.margin !== undefined) {
            if (o.bar.marginX === undefined) o.bar.marginX = o.bar.margin
            if (o.bar.marginY === undefined) o.bar.marginY = 0
        }
        fill(o, fallback)
        const c = Object.assign({}, palette.colors || {}, raw.colors || {})
        // keys older colour blocks may not have
        if (c.panel === undefined) c.panel = c.barBg
        if (c.island === undefined) c.island = c.barBg
        if (c.onIsland === undefined) c.onIsland = c.text
        if (c.warm === undefined) c.warm = c.warn
        c.blue = c.blue ?? c.info
        c.cyan = c.cyan ?? c.info
        c.purple = c.purple ?? c.accent
        c.magenta = c.magenta ?? c.purple
        c.foam = c.foam ?? c.cyan
        o.colors = c
        o.paletteSystem = palette.system || {}
        return o
    }

    FileView {
        id: file
        path: Quickshell.shellPath("config.json")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const o = root.parse(text())
            if (o) root.raw = o
            else console.warn("config.json has a syntax error. Keeping the previous values.")
        }
    }
    FileView {
        id: paletteFile
        path: root.paletteName !== "" ? Quickshell.shellPath("palettes/" + root.paletteName + ".json") : ""
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    Component.onCompleted: {
        const o = parse(file.text())
        if (o) raw = o
    }
}

# AGENTS.md

Guide for AI agents (and humans) working on this Quickshell desktop shell. Read it before changing anything.

## What this is

A Wayland desktop shell for Hyprland, written in QML on Quickshell (0.3.x, Qt 6.7+). It has a bar, a morphing "dynamic island" (eyes, music, toasts, control center), panels, a launcher, a lock screen, wallpaper and desktop widgets, popups (clipboard, wallpaper picker, region selector), IPC, and palette-driven theming.

**Performance and memory are the top priority.** See "Performance rules". When in doubt, choose the lighter option.

## Layout

    shell.qml            entry point: creates the top-level modules
    config.json          the ONE user config file (see config.md for every key)
    config.md            user documentation of every config key and IPC command
    theming.md           how palettes are exported to other apps
    palettes/*.json      colour palettes (the "colors" block)
    templates/*          files rendered with palette colours for other apps
    core/                Config.qml (loads + merges config), Theme.qml (colours, sizes)
    services/            singletons: state and system access, no visuals
    components/          small reusable visual pieces (Pill, Icon, Slider, Eyes, ...)
    modules/bar/         the bar: Bar.qml (one window per monitor), Workspaces, pills
    modules/island/      Island.qml (the morphing shape) and its states
    modules/panels/      dropdown panels hanging from the bar (PanelDrop hosts them)
    modules/launcher, lock, wallpaper, clipboard, capture, widgets, ipc

Imports use the `qs.` prefix: `import qs.core`, `import qs.components`, `import qs.services`, `import qs.modules.bar`.

## How things connect

- **Config:** read values with `Config.v.section.key`. It is the merge of the palette file, `config.json`, and built-in fallbacks (`Config.fallback`) for keys added later, so an older `config.json` keeps working. It reloads live.
- **Theme:** `Theme.px(n)` scales a size by `scale`. Colours are `Theme.accent`, `Theme.text`, etc. `Theme.resolve("accent")` turns a colour name or hex from config into a colour.
- **Island:** one `Rectangle`-like shape whose `mode` is computed from state (`wantMode`): control > toastFull > toast > musicFull > music > idle. Heavy modes load asynchronously first, then the shape grows.
- **Panels:** `Panels.toggle(name, screenName, x)` opens a panel. `PanelDrop` (inside each bar window) shows it. The control center is not a panel, it is the island expanded (`name == "control"`).
- **Popups** (clipboard, wallpaper picker, launcher, region selector) are their own layer-shell windows created only while open.
- **IPC:** `modules/ipc/Ipc.qml` holds every `IpcHandler`. Users call them with `qsctl <target> <function>`.

## Rules (breaking these causes real bugs)

1. **Never name a property `on` + Capital letter** (like `onIsland`, `onAccent`). Its change signal clashes with the handler of the property without the prefix, and the value silently stays black/empty. Use names like `islandText`, `accentText`.
2. **Do not name properties `top`, `left`, `right`, `bottom`** on Items (QML reserves them). Use `edge`, `atTop`, etc.
3. **No hardcoded colours or sizes.** Colours come from `Theme`; sizes go through `Theme.px()`. Text sitting directly on the island uses `Theme.islandText` / `Theme.islandTextDim`; on the bar use `Theme.text`.
4. **New settings go in `config.json`, and in `Config.fallback`** with a default, and in `config.md`.
5. **Do not resize or recreate layer-shell windows while animating.** The bar window has a fixed height on purpose; resizing it caused flicker.
6. **Do not write through symlinks** when exporting files (the theming code removes a symlink first).
7. **Every `MouseArea` that is clickable sets `cursorShape: Qt.PointingHandCursor`.**
8. **Icons are Material Symbols names** (`Icon { name: "wifi" }`). Do not use emoji or text glyphs.
9. After a change, run the shell from a terminal (`qs`) and read the output. Fix every warning you caused.

## Performance rules

- **Create things only while visible.** Use `Loader { active: ... }` (with `asynchronous: true` for big content) and `LazyLoader` for windows. Destroy after the fade-out finishes.
- **Poll only when needed.** A `Timer` should have `running:` tied to something visible. Heavy commands (`ps`, `top`, `nmcli` scans, `cliphist`) run on demand, not on a schedule. Constant timers are only for cheap, always-needed data (clock, CPU, memory).
- **No per-frame work when idle.** Animations use `running:` bound to visibility. Canvas repaints only on change.
- **Images:** always set `sourceSize`, `asynchronous: true`, and `cache: false` for large images (wallpapers decode at screen size).
- **Animations:** one animation per thing. Do not stack a `Behavior` on top of something that already animates (it lags). The island only animates size during a mode change, then follows content directly.
- **Lists:** use `ListView`/`GridView` (they only create visible rows). Never build hundreds of items in a `Repeater` inside a `Column`.
- **Avoid shader effects** (blur, shadows, `layer.enabled`) except where there is no alternative (the lock screen blur exists only while locked).
- **Process lists/JSON:** parse once, keep small objects. Do not keep unbounded history; cap arrays.
- Measure before and after when adding a feature: `ps -o rss= -p $(pgrep -x quickshell)` after a few minutes.

## Adding things

**A bar pill.** Add a `Pill { ... }` in `modules/bar/Bar.qml` (left or right `RowLayout`). Use `clickable: true` and `onClicked`. If it needs data, add a service first.

**A service** (`services/Thing.qml`):

    pragma Singleton
    import Quickshell
    import QtQuick
    import qs.core
    Singleton {
        property int value: 0
        Timer { running: false; interval: 2000; onTriggered: {} }   // only run when needed
    }

Reference it anywhere as `Thing.value`. Singletons are created on first use: touch it from `shell.qml` (see `Sounds.init()`) if it must run from start.

**A panel.** Create `modules/panels/ThingPanel.qml` as a `ColumnLayout` with `property real panelWidth: Theme.px(Config.v.panels.width)`. Register it in `PanelDrop.qml` (a `Component` and a line in `sourceComponent`), then open it with `Panels.toggle("thing", screenName, x)`.

**A control center tile.** Add a `Tile` in `modules/island/ControlCenter.qml`. If it expands, add a `Component` with a `Detail { ... }` body and register it in the dropdown `Loader`.

**An island state.** Add a mode to `wantMode` and `targetW/targetH` in `Island.qml`, a `Loader` in the body, and (if heavy) `asynchronous: true` with `onLoaded: root.commit()`.

**A popup window.** Copy `modules/clipboard/ClipboardPopup.qml`: a `Scope` with a `LazyLoader` and `OverlayWindow`, opened through `Popups.toggle("name")`.

**A desktop widget.** Add a component in `modules/widgets/`, instantiate it in `modules/wallpaper/WallpaperWindow.qml`, and add its config under `widgets`.

**An IPC command.** Add a function with typed arguments to an `IpcHandler` in `modules/ipc/Ipc.qml` (`function name(arg: string): void { ... }`), then document it in `config.md` and `keybinds.example.conf`.

**A themed app.** Add a file to `templates/` using `{{accent}}`, `{{bg.hex}}`, etc., and a target in `theming.targets`. See `theming.md`.

**A config key.** Add it to `config.json`, to `Config.fallback` in `core/Config.qml`, and to `config.md`.

## Theming and settings

- Templates use `{{token}}`, `{{token.hex}}`, `{{token.rgb}}`. New tokens go in `Theming.tokens()`. Palettes may define extra colour names and a `system.cursor`.
- `extras/theme.sh` applies GTK/GSettings/cursor/Qt from `SHELL_*` environment variables. Set the cursor in GSettings too, or apps that read GSettings lose the pointer.
- The settings popup (`modules/settings/`) edits any key generically. A new config key shows up there automatically; fixed-choice keys are listed in `Settings.enums`.
- Workspace alerts come from Hyprland raw events (`openwindow`, `urgent`) in `services/WorkspaceActivity.qml`.
- After a shell reload, `NotificationServer` re-announces old notifications; `Notifs` ignores those for toasts and sounds.

## Hyprland notes

The user's Hyprland uses the Lua config. `Hyprland.dispatch()` wraps strings in `hl.dispatch(...)`, so send Lua such as `hl.dsp.focus({ workspace = "2" })` (see `services/Hypr.qml`; `hyprland.lua` in config switches to legacy syntax). Workspaces are per monitor: each bar filters `Hyprland.workspaces` by `w.monitor.name`.

## Things to verify by running (not testable by reading)

Lock screen (PAM service in `lock.pamConfig`), session-lock behaviour, screen capture commands, Bluetooth and PipeWire device lists, tray menus. Test the lock screen only with a second TTY available.

## Style

Small files, one job each. Comments explain *why*, not what. Keep user-facing text short and plain. Update `config.md` whenever behaviour or config changes.

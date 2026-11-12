import Quickshell
import Quickshell.Io
import QtQuick
import qs.core
import qs.services

// Keybind commands: qs ipc call <target> <function> [argument]
Scope {
    IpcHandler {
        target: "control"
        function toggle(): void { IslandState.collapse(); Panels.toggleFocused("control") }
        function open(): void {
            if (Panels.open === "control") return
            IslandState.collapse()
            const s = Hypr.focusedScreen()
            Panels.openAt("control", s, Hypr.centerX(s))
        }
        function close(): void { Panels.close() }
    }
    IpcHandler {
        target: "panel"
        // names: wifi, bluetooth, volume, battery, vitals, calendar, notifications
        function toggle(name: string): void { Panels.toggleFocused(name) }
        function close(): void { Panels.close() }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { Panels.toggleFocused("notifications") }
        function dnd(): void { Notifs.toggleDnd() }
        function dndOn(): void { Notifs.dnd = true }
        function dndOff(): void { Notifs.dnd = false }
        function clear(): void { Notifs.clearAll() }
        function dismissToast(): void { Toasts.dismissCurrent() }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void { Popups.toggle("clipboard") }
        function close(): void { if (Popups.open === "clipboard") Popups.close() }
    }
    IpcHandler {
        target: "capture"
        function screenshot(mode: string): void { Capture.screenshot(mode, Hypr.focusedScreen(), true) }   // region | screen | annotate
        function record(mode: string): void { Capture.record(mode, Hypr.focusedScreen(), true) }          // screen | region
        function toggleRecord(): void { Capture.toggleRecord(Hypr.focusedScreen()) }
        function stopRecord(): void { Capture.stop() }
    }
    IpcHandler {
        target: "volume"
        function up(): void { Audio.nudge(Config.v.audio.step) }
        function down(): void { Audio.nudge(-Config.v.audio.step) }
        function mute(): void { Audio.toggleMute() }
        function set(percent: int): void { Audio.setVolume(percent / 100) }
        function micMute(): void { Audio.toggleMicMute() }
    }
    IpcHandler {
        target: "brightness"
        function up(): void { Backlight.screen.nudge(5) }
        function down(): void { Backlight.screen.nudge(-5) }
        function set(percent: int): void { Backlight.screen.set(percent / 100) }
        function kbdUp(): void { Backlight.keys.nudge(20) }
        function kbdDown(): void { Backlight.keys.nudge(-20) }
    }
    IpcHandler {
        target: "media"
        function playPause(): void { const p = Media.islandPlayer ?? Media.player; if (p) p.togglePlaying() }
        function next(): void { const p = Media.islandPlayer ?? Media.player; if (p) p.next() }
        function previous(): void { const p = Media.islandPlayer ?? Media.player; if (p) p.previous() }
        function expand(): void {
            if (IslandState.expanded === "music") IslandState.collapse()
            else IslandState.expand("music", Hypr.focusedScreen())
        }
    }
    IpcHandler {
        target: "island"
        function collapse(): void { Panels.close(); IslandState.collapse() }
    }
    IpcHandler {
        target: "session"
        function lock(): void { Session.lock() }
        function suspend(): void { Session.run(Config.v.session.suspend) }
        function hibernate(): void { Session.run(Config.v.session.hibernate) }
        function logout(): void { Session.run(Config.v.session.logout) }
        function reboot(): void { Session.run(Config.v.session.reboot) }
        function poweroff(): void { Session.run(Config.v.session.poweroff) }
    }
    IpcHandler {
        target: "lock"
        // hypridle:  lock_cmd = qs ipc call lock lock
        function lock(): void { Lock.lock() }
        function locked(): bool { return Lock.locked }
    }
    IpcHandler {
        target: "mood"       // test the eyes: qsctl mood set angry | qsctl mood auto
        function set(name: string): void { Mood.set(name) }
        function auto(): void { Mood.auto() }
        function get(): string { return Mood.current }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { Popups.toggle("settings") }
    }
    IpcHandler {
        target: "idle"
        function toggle(): void { Idle.toggle() }
    }
    IpcHandler {
        target: "wallpaper"
        function picker(): void { Popups.toggle("wallpaper") }
        function next(): void { Wallpaper.step(1) }
        function prev(): void { Wallpaper.step(-1) }
        function random(): void { Wallpaper.random() }
        function set(path: string): void { Wallpaper.set(path) }
        function reload(): void { Wallpaper.refresh() }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Launcher.toggle() }
        function open(): void { Launcher.show() }
        function close(): void { Launcher.hide() }
    }
    IpcHandler {
        target: "theme"
        function set(name: string): void { Theming.set(name) }
        function next(): void { Theming.next() }
        function apply(): void { Theming.apply(false) }
        function get(): string { return Theming.current }
        function list(): string { return Theming.names.join(", ") }
    }
}

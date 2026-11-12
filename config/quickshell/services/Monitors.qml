pragma Singleton
import Quickshell
import QtQuick
import qs.core

// Which monitors get a bar, and which one is "primary".
Singleton {
    readonly property string primary: Config.v.monitors.primary !== ""
        ? Config.v.monitors.primary
        : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
    function isPrimary(name) { return name === primary }
    function allowed(name) {
        const m = Config.v.monitors
        if (m.include.length > 0 && !m.include.includes(name)) return false
        return !m.exclude.includes(name)
    }
    readonly property var barScreens: Array.from(Quickshell.screens).filter(s => allowed(s.name))
}

pragma Singleton
import Quickshell
import Quickshell.Hyprland
import qs.core

// Hyprland 0.55+ uses Lua: Hyprland.dispatch() wraps the string in hl.dispatch(...).
// config.json "hyprland.lua": false switches back to the old "workspace 2" style.
Singleton {
    function dispatch(lua, legacy) { Hyprland.dispatch(Config.v.hyprland.lua ? lua : legacy) }
    function focusedScreen() {
        const m = Hyprland.focusedMonitor
        return m ? m.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
    }
    function centerX(name) {
        const s = Quickshell.screens.find(x => x.name === name)
        return s ? s.width / 2 : 0
    }
    function focusWorkspace(id) {
        dispatch('hl.dsp.focus({ workspace = "' + id + '" })', "workspace " + id)
    }
}

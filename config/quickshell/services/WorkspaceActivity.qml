pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.core

// Remembers workspaces where something happened while you were not looking:
//  - a window opened on a workspace that is not visible
//  - a window asked for attention (Hyprland "urgent", for example a browser opening a link)
// The bar paints those workspaces in a different colour until you visit them.
Singleton {
    id: root
    property var marked: ({})        // workspace id -> true

    function mark(id) {
        if (!Config.v.workspaces.attention || id <= 0 || marked[id]) return
        const m = Object.assign({}, marked); m[id] = true; marked = m
    }
    function clear(id) {
        if (!marked[id]) return
        const m = Object.assign({}, marked); delete m[id]; marked = m
    }
    function idOfName(name) {
        const w = Array.from(Hyprland.workspaces.values).find(x => x.name === name)
        return w ? w.id : (/^\d+$/.test(name) ? parseInt(name) : -1)
    }
    function visible(id) {
        return Array.from(Hyprland.monitors.values).some(m => m.activeWorkspace && m.activeWorkspace.id === id)
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (!Config.v.workspaces.attention) return
            const d = ev.data
            if (ev.name === "openwindow") {
                const id = root.idOfName(d.split(",")[1])
                if (id > 0 && !root.visible(id)) root.mark(id)
            } else if (ev.name === "urgent") {
                const t = Array.from(Hyprland.toplevels.values).find(x => String(x.address).replace(/^0x/, "") === d)
                const id = t && t.workspace ? t.workspace.id : -1
                if (id > 0 && !root.visible(id)) root.mark(id)
            } else if (ev.name === "workspacev2" || ev.name === "destroyworkspacev2") {
                root.clear(parseInt(d.split(",")[0]))
            } else if (ev.name === "focusedmonv2") {
                root.clear(parseInt(d.split(",")[1]))
            }
        }
    }
}

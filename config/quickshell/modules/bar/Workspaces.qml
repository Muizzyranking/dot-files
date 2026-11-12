import QtQuick
import Quickshell.Hyprland
import qs.core
import qs.components
import qs.services

// Shows the workspaces that live on THIS bar's monitor (a workspace opened on monitor 2
// only appears on monitor 2's bar). The visible workspace of the monitor has the
// highlight: accent colour when this monitor has focus, a muted one when it does not.
Pill {
    id: root
    required property string screenName
    padding: Theme.px(3)

    readonly property var mon: Array.from(Hyprland.monitors.values).find(m => m.name === screenName) ?? null
    readonly property bool monitorFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === screenName
    readonly property int activeId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1
    readonly property var list: Array.from(Hyprland.workspaces.values)
        .filter(w => w.id > 0 && w.monitor && w.monitor.name === screenName).sort((a, b) => a.id - b.id)
    readonly property int activeIndex: list.findIndex(w => w.id === activeId)
    onActiveIdChanged: WorkspaceActivity.clear(activeId)
    property real pos: Math.max(0, activeIndex)
    Behavior on pos { NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
    visible: list.length > 0

    Row {
        spacing: Theme.px(2)
        Repeater {
            model: root.list
            delegate: Rectangle {
                id: chip
                required property var modelData
                required property int index
                readonly property real w: Math.max(0, 1 - Math.abs(index - root.pos))
                // something happened here while you were elsewhere
                readonly property bool attn: Config.v.workspaces.attention && WorkspaceActivity.marked[modelData.id] === true && modelData.id !== root.activeId
                height: Theme.px(Config.v.bar.pill.height - 6)
                width: Math.max(height, txt.implicitWidth + Theme.px(14)) + Theme.px(Config.v.workspaces.activeExtra) * w
                radius: height / 2
                color: attn ? Theme.resolve(Config.v.workspaces.attentionColor) : Qt.alpha(root.monitorFocused ? Theme.accent : Theme.surfaceHi, w)

                Label {
                    id: txt
                    anchors.centerIn: parent
                    text: Config.v.workspaces.label === "name" ? chip.modelData.name : String(chip.modelData.id)
                    color: chip.attn ? Theme.accentText : Qt.tint(Theme.textDim, Qt.alpha(root.monitorFocused ? Theme.accentText : Theme.text, chip.w))
                    font.weight: chip.w > 0.5 ? Font.DemiBold : Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hypr.focusWorkspace(chip.modelData.id) }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.components
import qs.services

// Drag to select an area. Esc cancels. Windows exist only while selecting.
Variants {
    model: Selector.active ? Quickshell.screens : []

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-selector"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        property real sx: 0
        property real sy: 0
        property real ex: 0
        property real ey: 0
        property bool dragging: false
        readonly property real rx: Math.min(sx, ex)
        readonly property real ry: Math.min(sy, ey)
        readonly property real rw: dragging ? Math.abs(ex - sx) : 0
        readonly property real rh: dragging ? Math.abs(ey - sy) : 0
        readonly property color dim: Qt.rgba(0, 0, 0, 0.45)

        Item {
            focus: true
            Keys.onEscapePressed: Selector.cancel()
            Shortcut { sequence: "Escape"; onActivated: Selector.cancel() }
        }

        // dim everything except the selection
        Rectangle { x: 0; y: 0; width: win.width; height: win.ry; color: win.dim }
        Rectangle { x: 0; y: win.ry + win.rh; width: win.width; height: win.height - win.ry - win.rh; color: win.dim }
        Rectangle { x: 0; y: win.ry; width: win.rx; height: win.rh; color: win.dim }
        Rectangle { x: win.rx + win.rw; y: win.ry; width: win.width - win.rx - win.rw; height: win.rh; color: win.dim }
        Rectangle {
            visible: win.dragging
            x: win.rx; y: win.ry; width: win.rw; height: win.rh
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
        }
        Rectangle {
            visible: win.dragging && win.rw > 40
            x: Math.min(win.rx, win.width - width - 8)
            y: win.ry + win.rh + 8 + height > win.height ? win.ry - height - 8 : win.ry + win.rh + 8
            width: sl.implicitWidth + Theme.px(16); height: Theme.px(24)
            radius: Theme.px(8)
            color: Theme.panel
            Label { id: sl; anchors.centerIn: parent; text: Math.round(win.rw) + " × " + Math.round(win.rh); font.pixelSize: Theme.fontSize - 1 }
        }
        Label {
            visible: !win.dragging
            anchors.centerIn: parent
            text: "Drag to select an area  ·  Esc to cancel"
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            onPressed: m => { win.sx = m.x; win.ex = m.x; win.sy = m.y; win.ey = m.y; win.dragging = true }
            onPositionChanged: m => { if (win.dragging) { win.ex = m.x; win.ey = m.y } }
            onReleased: m => {
                const ok = win.rw > 4 && win.rh > 4
                const g = Math.round(win.modelData.x + win.rx) + "," + Math.round(win.modelData.y + win.ry)
                    + " " + Math.round(win.rw) + "x" + Math.round(win.rh)
                win.dragging = false
                if (ok) Selector.finish(g)
                else Selector.cancel()
            }
        }
    }
}

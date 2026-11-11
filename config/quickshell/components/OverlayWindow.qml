import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// A standalone popup: a full-screen transparent overlay with a centered card.
PanelWindow {
    id: win
    property bool open: false
    property real cardWidth: Theme.px(560)
    property real cardHeight: Theme.px(440)
    default property alias content: card.data
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    Item {
        focus: true
        Keys.onEscapePressed: win.closeRequested()
        Shortcut { sequence: "Escape"; onActivated: win.closeRequested() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: win.cardWidth
        height: win.cardHeight
        radius: Theme.px(Config.v.panels.radius)
        color: Theme.panel
        border.width: 1
        border.color: Theme.surfaceHi
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core
import qs.components
import qs.services
import qs.modules.panels
import qs.modules.island

// One bar window per monitor (see config.json "monitors"). The window has a fixed height:
// resizing it while popups open or close caused flicker. Only the bar, the island and the
// open panel catch clicks; the rest is see-through.
Variants {
    model: Monitors.barScreens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property real barH: Theme.px(Config.v.bar.height)
        readonly property real mx: Theme.px(Config.v.bar.marginX)     // left and right
        readonly property real my: Theme.px(Config.v.bar.marginY)     // top
        readonly property bool panelOpen: Panels.open !== "" && Panels.screenName === modelData.name
        readonly property bool islandOpen: IslandState.expanded !== "" && IslandState.screenName === modelData.name
        readonly property bool anyOpen: panelOpen || islandOpen

        anchors { top: true; left: true; right: true }
        implicitHeight: my + barH + Theme.px(Config.v.panels.maxHeight)
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: my + barH
        color: "transparent"
        mask: Region { item: island; Region { item: win.anyOpen ? full : bg } }
        WlrLayershell.namespace: "qs-bar"
        WlrLayershell.keyboardFocus: win.anyOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onAnyOpenChanged: if (anyOpen) keys.forceActiveFocus()

        SystemClock { id: clock; precision: SystemClock.Minutes }
        IdleInhibitor {
            window: win
            enabled: Idle.active && Config.v.modules.idleInhibitor && win.modelData === Quickshell.screens[0]
        }

        Item { id: full; anchors.fill: parent }
        MouseArea {
            anchors.fill: parent
            enabled: win.anyOpen
            onClicked: { Panels.close(); IslandState.collapse() }
        }
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: { Panels.close(); IslandState.collapse() }
            Shortcut { sequence: "Escape"; enabled: win.anyOpen; onActivated: { Panels.close(); IslandState.collapse() } }
        }

        // Bar background: translucent, rounded at the bottom corners
        Rectangle {
            id: bg
            x: win.mx
            y: win.my
            width: parent.width - win.mx * 2
            height: win.barH
            color: Qt.alpha(Theme.barBg, Config.v.bar.opacity)
            topLeftRadius: win.my > 0 ? Theme.px(Config.v.bar.radius) : 0
            topRightRadius: win.my > 0 ? Theme.px(Config.v.bar.radius) : 0
            bottomLeftRadius: Theme.px(Config.v.bar.radius)
            bottomRightRadius: Theme.px(Config.v.bar.radius)
            border.width: Config.v.bar.border
            border.color: Qt.alpha(Theme.text, Config.v.bar.borderOpacity)
        }

        PanelDrop {
            id: drop
            request: win.panelOpen && Panels.open !== "control" ? Panels.open : ""
            requestX: Panels.anchorX
            edge: bg.y + bg.height
        }

        // LEFT
        RowLayout {
            anchors { left: bg.left; leftMargin: Theme.px(Config.v.bar.outerPadding); verticalCenter: bg.verticalCenter }
            spacing: Theme.px(Config.v.bar.spacing)

            Rectangle {
                implicitWidth: Theme.px(Config.v.bar.pill.height); implicitHeight: implicitWidth
                radius: width / 2
                color: Theme.accent
                Icon { anchors.centerIn: parent; name: "apps"; color: Theme.accentText }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Launcher.toggle() }
            }
            Pill {
                clickable: true
                onClicked: Panels.toggle("calendar", win.screen.name, mapToItem(null, width / 2, 0).x)
                Label { text: Qt.formatDateTime(clock.date, Config.v.clock.timeFormat) }
                Label { text: Qt.formatDateTime(clock.date, Config.v.clock.dateFormat); color: Theme.textDim }
            }
            Pill {
                clickable: true
                onClicked: m => m.button === Qt.RightButton ? Notifs.toggleDnd()
                    : Panels.toggle("notifications", win.screen.name, mapToItem(null, width / 2, 0).x)
                Icon {
                    name: Notifs.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
                    color: Notifs.dnd ? Theme.textDim : Notifs.count > 0 ? Theme.accent : Theme.text
                }
            }
            Pill {
                visible: Config.v.modules.idleInhibitor
                clickable: true
                onClicked: Idle.toggle()
                Icon { name: "coffee"; color: Idle.active ? Theme.accent : Theme.textFaint }
            }
            Workspaces { screenName: win.modelData.name }
        }

        // RIGHT
        RowLayout {
            anchors { right: bg.right; rightMargin: Theme.px(Config.v.bar.outerPadding); verticalCenter: bg.verticalCenter }
            spacing: Theme.px(Config.v.bar.spacing)

            Pill {
                visible: Capture.recording
                clickable: true
                spacing: Theme.px(6)
                onClicked: Capture.stop()
                Icon { name: "fiber_manual_record"; color: Theme.bad }
                Label { text: Math.floor(Capture.elapsed / 60) + ":" + String(Capture.elapsed % 60).padStart(2, "0"); color: Theme.bad }
            }

            Pill {
                visible: SystemTray.items.values.length > 0 && (Config.v.monitors.tray !== "primary" || Monitors.isPrimary(win.modelData.name))
                spacing: Theme.px(8)
                Repeater {
                    model: SystemTray.items
                    delegate: Item {
                        id: t
                        required property var modelData
                        implicitWidth: Theme.px(16); implicitHeight: Theme.px(16)
                        IconImage { anchors.fill: parent; source: t.modelData.icon }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: m => {
                                if (m.button === Qt.LeftButton && !t.modelData.onlyMenu) t.modelData.activate()
                                else if (m.button === Qt.MiddleButton) t.modelData.secondaryActivate()
                                else if (t.modelData.hasMenu) {
                                    const p = t.mapToItem(win.contentItem, 0, t.height)
                                    t.modelData.display(win, p.x, p.y)
                                }
                            }
                        }
                    }
                }
            }

            VitalsPill { onClicked: Panels.toggle("vitals", win.screen.name, mapToItem(null, width / 2, 0).x) }

            Pill {
                spacing: Theme.px(2)
                padding: Theme.px(6)
                IconButton {
                    name: Net.icon
                    tone: Net.wifiEnabled && (Net.wifiConnected || Net.ethernet) ? Theme.text : Theme.textDim
                    onClicked: Panels.toggle("wifi", win.screen.name, centerX())
                }
                IconButton {
                    name: Bt.icon
                    tone: Bt.connected > 0 ? Theme.info : Bt.enabled ? Theme.text : Theme.textDim
                    onClicked: Panels.toggle("bluetooth", win.screen.name, centerX())
                }
                IconButton {
                    name: Audio.icon
                    tone: Audio.muted ? Theme.textDim : Theme.text
                    onClicked: m => m.button === Qt.RightButton ? Audio.toggleMute() : Panels.toggle("volume", win.screen.name, centerX())
                    onWheel: w => Audio.nudge(w.angleDelta.y > 0 ? Config.v.audio.step : -Config.v.audio.step)
                }
            }

            BatteryIcon { onClicked: Panels.toggle("battery", win.screen.name, mapToItem(null, width / 2, 0).x) }
        }

        // The island morphs between eyes, music, toast and control center.
        Island {
            id: island
            screenName: win.modelData.name
            floating: win.my > 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: win.my
        }
    }
}

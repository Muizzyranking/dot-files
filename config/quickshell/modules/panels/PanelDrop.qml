import QtQuick
import qs.core
import qs.components
import qs.services

// A panel that hangs from the bar. Switching panels collapses the open one first,
// then opens the new one at its own position
Item {
    id: root
    anchors.fill: parent
    property string request: ""
    property real requestX: 0
    property real edge: 0

    property string shown: ""
    property real shownX: 0
    property bool open: false
    property bool swapping: false

    readonly property real pad: Theme.px(Config.v.panels.padding)
    readonly property real rad: Theme.px(Config.v.panels.radius)
    readonly property real gap: Theme.px(Config.v.panels.gap)
    readonly property color tone: Qt.alpha(Theme.panel, Config.v.panels.opacity)

    function swapNow() { swapping = false; shown = request; shownX = requestX; open = true }
    function sync() {
        if (request === "") { swapping = false; open = false; return }
        if (open && shown === request) return
        if (revealed > 0.02) { swapping = true; open = false }
        else swapNow()
    }
    onRequestChanged: sync()

    property real revealed: 0
    Behavior on revealed {
        NumberAnimation {
            duration: root.open ? Config.v.panels.openMs : Config.v.panels.closeMs
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }
    onRevealedChanged: if (swapping && revealed <= 0.02) swapNow()
    onOpenChanged: revealed = open ? 1 : 0

    readonly property bool settled: revealed > 0.98
    visible: revealed > 0.001

    property real targetW: loader.item ? loader.item.panelWidth + pad * 2 : 0
    property real targetH: loader.item ? loader.item.implicitHeight + pad * 2 : 0
    Behavior on targetW { enabled: root.settled; NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
    Behavior on targetH { enabled: root.settled; NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
    readonly property real cardX: Math.max(4, Math.min(width - targetW - 4, shownX - targetW / 2))

    Rectangle {
        x: root.cardX; y: root.edge + root.gap
        width: root.targetW
        height: root.targetH * root.revealed
        color: root.tone
        clip: true
        radius: root.rad
        border.width: Config.v.panels.border
        border.color: Qt.alpha(Theme.resolve(Config.v.panels.borderColor), Config.v.panels.borderOpacity)

        MouseArea { anchors.fill: parent }   // clicks inside never close the panel

        Loader {
            id: loader
            x: root.pad; y: root.pad
            width: item ? item.panelWidth : 0
            opacity: Math.min(1, root.revealed * 1.6)
            active: root.open || root.revealed > 0.001
            sourceComponent: root.shown === "wifi" ? wifiC
                : root.shown === "bluetooth" ? btC
                : root.shown === "volume" ? volC
                : root.shown === "battery" ? batC
                : root.shown === "vitals" ? vitC
                : root.shown === "notifications" ? notC
                : root.shown === "calendar" ? calC : null
        }
    }

    Component { id: wifiC; WifiPanel {} }
    Component { id: btC; BluetoothPanel {} }
    Component { id: volC; VolumePanel {} }
    Component { id: batC; BatteryPanel {} }
    Component { id: vitC; VitalsPanel {} }
    Component { id: notC; NotificationsPanel {} }
    Component { id: calC; CalendarPanel {} }
}

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.core
import qs.components
import qs.services

// The island is ONE shape that morphs between states; content fades inside it.
// Its sides flare out a little at the top (island.flare), like an inverted trapezoid.
// Priority: control center > full toast > toast > full music > music > eyes.
// Heavy content is built first, THEN the island grows, so the animation never stalls.
Item {
    id: root
    required property string screenName
    property bool floating: false           // true when the bar has a top margin

    readonly property var cfg: Config.v.island
    readonly property real pad: Theme.px(Config.v.panels.padding)
    readonly property real flare: Theme.px(cfg.flare)
    readonly property bool control: Panels.open === "control" && Panels.screenName === screenName
    readonly property bool mine: IslandState.screenName === screenName
    readonly property bool toastHere: Toasts.current !== null && Toasts.showsOn(screenName)
    readonly property string wantMode: control ? "control"
        : (IslandState.expanded === "toast" && mine && toastHere) ? "toastFull"
        : toastHere ? "toast"
        : (IslandState.expanded === "music" && mine && Media.active) ? "musicFull"
        : Media.active ? "music" : "idle"
    property string mode: "idle"
    readonly property bool compact: mode === "idle" || mode === "music" || mode === "toast"

    function loaderFor(m) { return m === "control" ? ctl : m === "toastFull" ? tfull : m === "musicFull" ? mfull : null }
    function commit() {
        const l = loaderFor(wantMode)
        if (!l || l.status === Loader.Ready) mode = wantMode
    }
    onWantModeChanged: commit()
    function closeAll() { Panels.close(); IslandState.collapse() }

    // The size only animates while the mode changes. Afterwards the island follows its
    // content directly (dropdowns, tabs), so nothing lags behind or jumps.
    property bool morphing: false
    onModeChanged: { morphing = true; morphT.restart() }
    Timer { id: morphT; interval: root.cfg.morphMs + 60; onTriggered: root.morphing = false }

    readonly property real idleW: Theme.px(cfg.idleWidth)
    readonly property real idleH: Theme.px(cfg.idleHeight)
    property real targetW: mode === "control" ? Theme.px(Config.v.panels.controlWidth)
        : mode === "toastFull" ? Theme.px(cfg.toastFullWidth)
        : mode === "toast" ? Theme.px(cfg.toastWidth)
        : mode === "musicFull" ? Theme.px(cfg.musicFullWidth) : idleW
    property real targetH: mode === "control" ? (ctl.item ? ctl.item.implicitHeight + pad * 2 : idleH)
        : mode === "toastFull" ? (tfull.item ? tfull.item.implicitHeight : Theme.px(cfg.toastHeight))
        : mode === "toast" ? Theme.px(cfg.toastHeight)
        : mode === "musicFull" ? Theme.px(cfg.musicFullHeight) : idleH
    property real w: targetW
    property real h: targetH
    property real br: compact ? Theme.px(cfg.bottomRadius) : Theme.px(cfg.expandedRadius)
    Behavior on w { enabled: root.morphing; NumberAnimation { duration: root.cfg.morphMs; easing.type: Easing.OutCubic } }
    Behavior on h { enabled: root.morphing; NumberAnimation { duration: root.cfg.morphMs; easing.type: Easing.OutCubic } }
    Behavior on br { NumberAnimation { duration: root.cfg.morphMs; easing.type: Easing.OutCubic } }

    width: w + flare * 2
    height: h

    // the shape: wide at the top, slightly narrower at the bottom
    readonly property real len: Math.max(1, Math.hypot(flare, height))
    readonly property real rb: br
    readonly property real rt: floating ? br : 0
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Theme.resolve(root.cfg.color)
            strokeColor: Qt.alpha(Theme.resolve(root.cfg.borderColor), root.cfg.borderOpacity)
            strokeWidth: root.cfg.border > 0 ? root.cfg.border : -1
            startX: root.rt; startY: 0
            PathLine { x: root.width - root.rt; y: 0 }
            PathQuad { controlX: root.width; controlY: 0; x: root.width - root.rt * root.flare / root.len; y: root.rt * root.height / root.len }
            PathLine { x: root.width - root.flare + root.rb * root.flare / root.len; y: root.height - root.rb * root.height / root.len }
            PathQuad { controlX: root.width - root.flare; controlY: root.height; x: root.width - root.flare - root.rb; y: root.height }
            PathLine { x: root.flare + root.rb; y: root.height }
            PathQuad { controlX: root.flare; controlY: root.height; x: root.flare - root.rb * root.flare / root.len; y: root.height - root.rb * root.height / root.len }
            PathLine { x: root.rt * root.flare / root.len; y: root.rt * root.height / root.len }
            PathQuad { controlX: 0; controlY: 0; x: root.rt; y: 0 }
        }
    }

    HoverHandler { onHoveredChanged: Toasts.hover(hovered) }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.compact ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: if (root.mode === "idle" && Config.v.eyes.blinkOnHover) eyes.blink()
        onClicked: m => {
            const topStrip = m.y <= root.idleH
            if (root.mode === "control") { if (topStrip) root.closeAll(); return }
            if (root.mode === "musicFull" || root.mode === "toastFull") {
                if (topStrip || m.button === Qt.RightButton) root.closeAll()
                return
            }
            if (m.button === Qt.RightButton || root.mode === "idle") {
                IslandState.collapse()
                Panels.toggle("control", root.screenName, root.mapToItem(null, root.width / 2, 0).x)
            } else if (root.mode === "music") IslandState.expand("music", root.screenName)
            else if (root.mode === "toast") IslandState.expand("toast", root.screenName)
        }
    }

    // content lives in the middle, so the flared edges stay empty
    Item {
        id: body
        x: root.flare
        width: root.w
        height: parent.height
        clip: true

        Eyes {
            id: eyes
            anchors.horizontalCenter: parent.horizontalCenter
            y: (root.idleH - height) / 2
            active: root.mode === "idle"
            opacity: root.mode === "idle" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        Rectangle {
            visible: Capture.recording && (root.mode === "idle" || root.mode === "music")
            width: Theme.px(8); height: width; radius: width / 2
            color: Theme.bad
            anchors.right: parent.right
            anchors.rightMargin: Theme.px(12)
            anchors.top: parent.top
            anchors.topMargin: (root.idleH - height) / 2
            SequentialAnimation on opacity {
                running: parent.visible
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.25; duration: 700 }
                NumberAnimation { from: 0.25; to: 1; duration: 700 }
            }
        }

        Loader {
            readonly property bool want: root.wantMode === "music"
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.idleW; height: root.idleH
            active: want || opacity > 0.01
            opacity: root.mode === "music" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            source: "MusicMini.qml"
        }
        Loader {
            readonly property bool want: root.wantMode === "toast"
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.px(root.cfg.toastWidth); height: Theme.px(root.cfg.toastHeight)
            active: want || opacity > 0.01
            opacity: root.mode === "toast" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            source: "ToastCompact.qml"
        }
        Loader {
            id: tfull
            readonly property bool want: root.wantMode === "toastFull"
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.px(root.cfg.toastFullWidth)
            asynchronous: true
            active: want || opacity > 0.01
            opacity: root.mode === "toastFull" ? 1 : 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.mode === "toastFull" ? 90 : 0 } NumberAnimation { duration: 170 } } }
            onLoaded: root.commit()
            source: "ToastFull.qml"
        }
        Loader {
            id: mfull
            readonly property bool want: root.wantMode === "musicFull"
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.px(root.cfg.musicFullWidth); height: Theme.px(root.cfg.musicFullHeight)
            asynchronous: true
            active: want || opacity > 0.01
            opacity: root.mode === "musicFull" ? 1 : 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.mode === "musicFull" ? 90 : 0 } NumberAnimation { duration: 170 } } }
            onLoaded: root.commit()
            source: "MusicFull.qml"
        }
        Loader {
            id: ctl
            readonly property bool want: root.wantMode === "control"
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.pad
            width: Theme.px(Config.v.panels.controlWidth) - root.pad * 2
            asynchronous: true
            active: want || opacity > 0.01
            opacity: root.mode === "control" ? 1 : 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.mode === "control" ? 110 : 0 } NumberAnimation { duration: 180 } } }
            onLoaded: root.commit()
            source: "ControlCenter.qml"
        }
    }
}

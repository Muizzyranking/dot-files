import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services
import qs.modules.widgets

// Background layer: wallpaper (cross-fades between images) plus desktop widgets.
// The window is transparent, so another wallpaper tool keeps working until you pick one here.
Variants {
    model: (Config.v.wallpaper.enabled || Config.v.widgets.clock.enabled) ? Quickshell.screens : []

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "qs-wallpaper"

        readonly property string src: Config.v.wallpaper.enabled && Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        readonly property int fill: Config.v.wallpaper.fit === "fit" ? Image.PreserveAspectFit
            : Config.v.wallpaper.fit === "stretch" ? Image.Stretch : Image.PreserveAspectCrop
        // decode at screen size (a little extra for cropping) so big images stay cheap
        readonly property real decodeW: modelData.width * modelData.devicePixelRatio * 1.25
        property int front: 0
        property var pending: null

        function load() {
            if (src === "") { imgA.source = ""; imgB.source = ""; return }
            const back = front === 0 ? imgB : imgA
            pending = back
            back.source = src
        }
        function swap(img) {
            if (pending !== img) return
            pending = null
            front = img === imgA ? 0 : 1
            clearT.restart()
        }
        onSrcChanged: load()
        Component.onCompleted: load()
        Timer {
            id: clearT
            interval: Config.v.wallpaper.transitionMs + 100
            onTriggered: (win.front === 0 ? imgB : imgA).source = ""
        }

        Image {
            id: imgA
            anchors.fill: parent
            asynchronous: true; cache: false
            fillMode: win.fill
            sourceSize.width: win.decodeW
            opacity: win.front === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Config.v.wallpaper.transitionMs; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready) win.swap(imgA)
        }
        Image {
            id: imgB
            anchors.fill: parent
            asynchronous: true; cache: false
            fillMode: win.fill
            sourceSize.width: win.decodeW
            opacity: win.front === 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Config.v.wallpaper.transitionMs; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready) win.swap(imgB)
        }

        DesktopClock { screenName: win.modelData.name }
    }
}

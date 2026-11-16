pragma Singleton
import Quickshell
import QtQuick
import qs.core
import qs.services

Singleton {
    id: root
    property string kind: ""        // "volume" | "brightness" | ""
    property real value: 0          // 0..1
    property bool muted: false
    property string screenName: ""  // monitor that was focused at the last change
    readonly property bool active: kind !== ""

    function showsOn(name) {
        const m = Config.v.meters.monitor
        return m === "all" || (m === "primary" ? Monitors.isPrimary(name) : name === screenName)
    }
    function bump(k, v, mu) {
        if (!Config.v.meters.enabled || !primed) return
        kind = k
        value = v
        muted = mu
        screenName = Hypr.focusedScreen()
        hold.restart()
    }
    Timer { id: hold; interval: Config.v.meters.holdMs; onTriggered: root.kind = "" }

    property bool primed: false
    Timer { interval: 2000; running: true; onTriggered: root.primed = true }

    Connections {
        target: Audio
        function onVolumeChanged() { root.bump("volume", Audio.volume, Audio.muted) }
        function onMutedChanged() { root.bump("volume", Audio.volume, Audio.muted) }
    }
    Connections {
        target: Backlight.screen
        function onValueChanged() { root.bump("brightness", Backlight.screen.value, false) }
    }
}

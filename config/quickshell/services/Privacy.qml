pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import qs.core
import qs.services

// Privacy indicators for the island: screen recording, camera, microphone and
// screen share in use. Add one by appending {icon, active} to `items`.
Singleton {
    id: root

    // a process holds a video device open
    property bool camera: false
    // apps capturing audio show up as Stream/Input/Audio nodes
    property bool mic: false
    // the desktop portal's screencast creates a Stream/Input/Video node
    property bool share: false

    readonly property var items: [
        { icon: "fiber_manual_record", active: Capture.recording, pulse: true },
        { icon: "videocam", active: root.camera },
        { icon: "mic", active: root.mic },
        { icon: "screen_share", active: root.share }
    ].filter(i => i.active)
    readonly property int count: items.length
    readonly property int space: count > 0 ? 16 * count + 6 * (count - 1) : 0

    PwObjectTracker { objects: streamList }

    readonly property var streamList: Pipewire.nodes ? Pipewire.nodes.values : []
    onStreamListChanged: recountT.restart()

    function recount() {
        let micCount = 0
        let sharing = false
        for (const o of streamList) {
            if (!o || !o.isStream) continue
            const cls = (o.properties || {})["media.class"] || ""
            if (cls === "Stream/Input/Audio") micCount++
            else if (cls === "Stream/Input/Video" && /screencast|portal|hyprland/i.test((o.name || "") + " " + (o.description || "")))
                sharing = true
        }
        root.mic = micCount > 0
        root.share = sharing
    }
    Timer { id: recountT; interval: 400; onTriggered: root.recount() }

    Process {
        id: camProbe
        command: ["fuser", "/dev/video0", "/dev/video1", "/dev/video2", "/dev/video3"]
        stdout: StdioCollector { onStreamFinished: root.camera = text.trim() !== "" }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: camProbe.running = true }
    Component.onCompleted: camProbe.running = true
}

pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.core

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    function setVolume(v) { if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(Config.v.audio.maxVolume, v)) }
    function nudge(d) { setVolume(volume + d) }
    function toggleMicMute() {
        const m = Pipewire.defaultAudioSource
        if (m && m.audio) m.audio.muted = !m.audio.muted
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }

    readonly property string icon: muted || volume <= 0 ? "volume_off"
                                 : volume < 0.34 ? "volume_mute"
                                 : volume < 0.67 ? "volume_down" : "volume_up"
}

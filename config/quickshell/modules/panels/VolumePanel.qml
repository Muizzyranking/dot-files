import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Output (up to audio.maxVolume) and input, with device switching.
ColumnLayout {
    property real panelWidth: Theme.px(Config.v.panels.width)
    spacing: Theme.px(12)

    AudioSection { kind: "sink"; title: "Output"; iconOn: "volume_up"; iconOff: "volume_off"; maxVol: Config.v.audio.maxVolume }
    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surfaceHi }
    AudioSection { kind: "source"; title: "Input"; iconOn: "mic"; iconOff: "mic_off"; maxVol: Config.v.audio.maxInput }
    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surfaceHi }
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(8)
        Icon { name: Sounds.enabled ? "notifications_active" : "notifications_off"; color: Sounds.enabled ? Theme.accent : Theme.textDim }
        Label { text: "System sounds"; Layout.fillWidth: true }
        Toggle { checked: Config.v.sounds.enabled && !Sounds.muted; onToggled: Sounds.muted = !Sounds.muted }
    }
}

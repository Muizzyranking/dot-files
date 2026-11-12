import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.core

ColumnLayout {
    id: sec
    property string kind: "sink"
    property string title: "Output"
    property string iconOn: "volume_up"
    property string iconOff: "volume_off"
    property real maxVol: 1
    property real thickness: Theme.px(6)
    property color labelColor: Theme.text

    readonly property var node: kind === "sink" ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
    readonly property var all: Pipewire.nodes ? Array.from(Pipewire.nodes.values) : []
    readonly property var devices: all.filter(n => n.audio && !n.isStream && (kind === "sink" ? n.isSink : !n.isSink))
    readonly property real vol: node && node.audio ? node.audio.volume : 0
    readonly property bool muted: node && node.audio ? node.audio.muted : false
    PwObjectTracker { objects: sec.all }

    function nameOf(n) { return n ? (n.nickname || n.description || n.name) : "No device" }
    Layout.fillWidth: true
    spacing: Theme.px(6)

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(8)
        IconButton {
            name: sec.muted ? sec.iconOff : sec.iconOn
            tone: sec.muted ? Theme.textDim : sec.labelColor
            onClicked: if (sec.node && sec.node.audio) sec.node.audio.muted = !sec.node.audio.muted
        }
        Label { text: sec.title; font.weight: Font.DemiBold; color: sec.labelColor; Layout.fillWidth: true }
        Label { text: Math.round(sec.vol * 100) + "%"; color: sec.vol > 1 ? Theme.warn : Theme.textDim }
    }
    Slider {
        Layout.fillWidth: true
        thickness: sec.thickness
        value: sec.vol / sec.maxVol
        marker: sec.maxVol > 1 ? 1 / sec.maxVol : -1
        tone: sec.muted ? Theme.textFaint : sec.vol > 1 ? Theme.warn : Theme.accent
        onMoved: v => { if (sec.node && sec.node.audio) sec.node.audio.volume = v * sec.maxVol }
    }
    Label {
        visible: sec.devices.length <= 1
        text: sec.nameOf(sec.node)
        color: Theme.textDim
        font.pixelSize: Theme.fontSize - 1
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
    Repeater {
        model: sec.devices.length > 1 ? sec.devices : []
        delegate: ListItem {
            required property var modelData
            Layout.fillWidth: true
            text: sec.nameOf(modelData)
            active: sec.node ? modelData.id === sec.node.id : false
            onClicked: {
                if (sec.kind === "sink") Pipewire.preferredDefaultAudioSink = modelData
                else Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}

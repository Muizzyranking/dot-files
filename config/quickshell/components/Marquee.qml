import QtQuick
import qs.core

// Single-line text that scrolls sideways only when it does not fit.
Item {
    id: root
    property string text: ""
    property color color: Theme.text
    property real pixelSize: Theme.fontSize
    property bool running: true
    property int alignment: Qt.AlignHCenter
    property real speed: Config.v.island.scrollSpeed   // pixels per second
    readonly property bool overflow: probe.implicitWidth > width
    property real offset: 0
    clip: true
    implicitHeight: probe.implicitHeight

    Text {
        id: probe
        visible: false
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
    }
    Row {
        id: row
        spacing: Theme.px(28)
        x: root.overflow ? root.offset : (root.alignment === Qt.AlignLeft ? 0 : (root.width - probe.implicitWidth) / 2)
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: root.overflow ? 2 : 1
            Text {
                text: root.text
                color: root.color
                font.family: Theme.fontFamily
                font.pixelSize: root.pixelSize
                font.weight: Font.Medium
            }
        }
    }
    SequentialAnimation on offset {
        running: root.overflow && root.running && root.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 1500 }
        NumberAnimation {
            from: 0
            to: -(probe.implicitWidth + row.spacing)
            duration: (probe.implicitWidth + row.spacing) / Math.max(5, root.speed) * 1000
        }
    }
    onOverflowChanged: offset = 0
    onTextChanged: offset = 0
}

import QtQuick
import qs.core

// value is 0..1. Emits moved(v) while dragging, clicking or scrolling.
Item {
    id: root
    property real value: 0
    property color tone: Theme.accent
    property real thickness: Theme.px(6)
    property real marker: -1      // optional tick position, 0..1
    signal moved(real v)
    implicitHeight: Math.max(Theme.px(20), thickness + Theme.px(10))
    implicitWidth: 200
    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2
        color: Theme.surfaceHi
        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            radius: parent.radius
            color: root.tone
        }
    }
    Rectangle {
        width: root.thickness + Theme.px(8); height: width; radius: width / 2
        color: Theme.text
        anchors.verticalCenter: parent.verticalCenter
        x: root.clamp(root.value) * (root.width - width)
        scale: area.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Config.v.animation.fast } }
    }
    Rectangle {
        visible: root.marker > 0 && root.marker < 1
        anchors.verticalCenter: parent.verticalCenter
        x: root.marker * root.width - 1
        width: 2; height: root.thickness + Theme.px(8)
        radius: 1; color: Theme.textFaint
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) { root.moved(root.clamp(mx / width)) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => root.moved(root.clamp(root.value + (w.angleDelta.y > 0 ? 0.03 : -0.03)))
    }
}

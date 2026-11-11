import QtQuick
import qs.core

Item {
    id: root
    property int count: 4
    property real barWidth: Theme.px(3)
    property real gap: Theme.px(2)
    property color tone: Theme.accent
    property bool running: true
    property var hs: [0.4, 0.8, 0.5, 0.9]
    implicitWidth: count * barWidth + (count - 1) * gap
    implicitHeight: Theme.px(14)

    Timer {
        running: root.running && root.visible
        repeat: true
        interval: 150
        onTriggered: {
            const a = []
            for (let i = 0; i < root.count; i++) a.push(0.25 + Math.random() * 0.75)
            root.hs = a
        }
    }
    Row {
        anchors.fill: parent
        spacing: root.gap
        Repeater {
            model: root.count
            Item {
                required property int index
                width: root.barWidth; height: root.height
                Rectangle {
                    width: parent.width
                    height: Math.max(2, root.height * (root.running ? (root.hs[index] ?? 0.5) : 0.25))
                    anchors.bottom: parent.bottom
                    radius: width / 2
                    color: root.tone
                    Behavior on height { NumberAnimation { duration: 140 } }
                }
            }
        }
    }
}

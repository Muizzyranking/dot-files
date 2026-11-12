import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Battery with the real percentage inside.
Item {
    id: root
    visible: Battery.present
    signal clicked()
    readonly property int pct: Battery.percent
    readonly property bool low: pct <= Config.v.battery.low
    readonly property color tone: pct <= low ? Theme.bad
                                : pct <= Config.v.battery.medium ? Theme.warn : Theme.good
    readonly property color textTone: low ? Theme.text : Theme.accentText
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: 1
        Rectangle {
            id: body
            implicitWidth: Theme.px(38)
            implicitHeight: Theme.px(18)
            radius: Theme.px(6)
            color: "transparent"
            border.width: 2
            border.color: root.tone
            Rectangle {
                x: 2; y: 2
                height: body.height - 4
                width: Math.max(0, (body.width - 4) * root.pct / 100)
                radius: Math.max(0, body.radius - 2)
                color: root.tone
                Behavior on width { NumberAnimation { duration: Config.v.animation.normal } }
            }
            RowLayout {
                anchors.centerIn: parent
                spacing: 0
                Icon { visible: Battery.plugged; name: "bolt"; size: Theme.px(11); color: root.textTone }
                Label { text: root.pct; color: root.textTone; font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold }
            }
        }
        Rectangle { implicitWidth: Theme.px(3); implicitHeight: Theme.px(7); radius: 1.5; color: root.tone }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}

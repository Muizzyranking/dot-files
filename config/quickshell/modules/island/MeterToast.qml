import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

Item {
    RowLayout {
        anchors { fill: parent; leftMargin: Theme.px(14); rightMargin: Theme.px(14) }
        spacing: Theme.px(10)
        Icon {
            name: Meters.kind === "brightness" ? "brightness_6"
                : (Meters.muted || Meters.value <= 0) ? "volume_off"
                : Meters.value > 0.5 ? "volume_up" : "volume_down"
            size: Theme.px(18)
            color: Theme.islandText
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.px(6)
            radius: height / 2
            color: Theme.surfaceHi
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.width * Math.max(0, Math.min(1, Meters.value))
                radius: parent.radius
                color: Meters.muted ? Theme.islandTextDim : Theme.accent
            }
        }
        Label {
            text: Math.round(Meters.value * 100) + "%"
            color: Theme.islandText
            font.pixelSize: Theme.fontSize - 1
        }
    }
}

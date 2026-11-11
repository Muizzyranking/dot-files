import QtQuick
import qs.core

// Segmented tabs with a sliding highlight. model: [{ icon, name }]
Rectangle {
    id: root
    property var model: []
    property int current: 0
    signal picked(int index)
    readonly property real cellW: model.length > 0 ? width / model.length : width
    implicitHeight: Theme.px(34)
    radius: Theme.px(12)
    color: Theme.surface

    Rectangle {
        y: 3; height: parent.height - 6
        width: root.cellW - 6
        x: root.current * root.cellW + 3
        radius: Theme.px(9)
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
    }
    Row {
        anchors.fill: parent
        Repeater {
            model: root.model
            delegate: Item {
                id: tb
                required property var modelData
                required property int index
                width: root.cellW; height: root.height
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.px(6)
                    Icon { name: tb.modelData.icon; size: Theme.px(15); color: root.current === tb.index ? Theme.accentText : Theme.textDim }
                    Label { text: tb.modelData.name; color: root.current === tb.index ? Theme.accentText : Theme.textDim }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(tb.index) }
            }
        }
    }
}

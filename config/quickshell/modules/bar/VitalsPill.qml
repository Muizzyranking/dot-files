import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

Pill {
    id: root
    clickable: true
    spacing: Theme.px(12)
    property var items: [
        { icon: "memory", value: SysStats.memory },
        { icon: "swap_vert", value: SysStats.swap },
        { icon: "developer_board", value: SysStats.cpu },
        { icon: "hard_drive", value: SysStats.disk }
    ]
    Repeater {
        model: root.items
        delegate: RowLayout {
            required property var modelData
            spacing: Theme.px(3)
            Icon { name: modelData.icon; size: Theme.iconSize - 1; color: Theme.vitalColor(modelData.value) }
            Label {
                text: Math.round(modelData.value) + "%"
                color: Theme.vitalColor(modelData.value)
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

RowLayout {
    id: r
    required property var row
    readonly property var val: Settings.get(row.path) ?? 0
    readonly property bool isInt: Number.isInteger(val)
    readonly property real step: isInt ? (Math.abs(val) >= 1000 ? 100 : Math.abs(val) >= 100 ? 10 : 1) : 0.05
    function commit(v) {
        if (isNaN(v)) return
        Settings.setPath(row.path, isInt ? Math.round(v) : Math.round(v * 1000) / 1000)
    }
    spacing: Theme.px(4)
    IconButton { name: "remove"; onClicked: r.commit(r.val - r.step) }
    Rectangle {
        implicitWidth: Theme.px(84); implicitHeight: Theme.px(30)
        radius: Theme.px(8)
        color: Theme.surface
        border.width: ti.activeFocus ? 1 : 0
        border.color: Theme.accent
        TextInput {
            id: ti
            anchors { fill: parent; margins: Theme.px(6) }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: String(r.val)
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            onEditingFinished: r.commit(parseFloat(text))
        }
    }
    IconButton { name: "add"; onClicked: r.commit(r.val + r.step) }
}

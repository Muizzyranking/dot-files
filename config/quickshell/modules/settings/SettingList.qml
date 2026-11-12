import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// A list of values, written as comma-separated text. Used for monitor names, exclude lists, ...
Rectangle {
    id: r
    required property var row
    readonly property var arr: Settings.get(row.path) ?? []
    readonly property bool numeric: arr.length > 0 && typeof arr[0] === "number"
    implicitWidth: Theme.px(260); implicitHeight: Theme.px(30)
    radius: Theme.px(8)
    color: Theme.surface
    border.width: ti.activeFocus ? 1 : 0
    border.color: Theme.accent
    TextInput {
        id: ti
        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
        verticalAlignment: Text.AlignVCenter
        text: r.arr.join(", ")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        selectByMouse: true
        clip: true
        onEditingFinished: {
            const parts = text.split(",").map(s => s.trim()).filter(s => s !== "")
            Settings.setPath(r.row.path, r.numeric ? parts.map(Number).filter(n => !isNaN(n)) : parts)
        }
    }
}

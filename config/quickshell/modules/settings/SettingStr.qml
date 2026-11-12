import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Text value. A colour like #89b4fa also shows a swatch.
RowLayout {
    id: r
    required property var row
    readonly property string val: String(Settings.get(row.path) ?? "")
    spacing: Theme.px(8)
    Rectangle {
        visible: /^#[0-9a-fA-F]{6,8}$/.test(r.val)
        implicitWidth: Theme.px(22); implicitHeight: implicitWidth; radius: width / 2
        color: visible ? r.val : "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.25)
    }
    Rectangle {
        implicitWidth: Theme.px(230); implicitHeight: Theme.px(30)
        radius: Theme.px(8)
        color: Theme.surface
        border.width: ti.activeFocus ? 1 : 0
        border.color: Theme.accent
        TextInput {
            id: ti
            anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
            verticalAlignment: Text.AlignVCenter
            text: r.val
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            clip: true
            onEditingFinished: if (text !== r.val) Settings.setPath(r.row.path, text)
        }
    }
}

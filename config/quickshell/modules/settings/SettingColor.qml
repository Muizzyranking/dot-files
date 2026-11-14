import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// A colour: click the swatch for the picker, or type a hex value.
RowLayout {
    id: r
    required property var row
    readonly property string val: String(Settings.get(row.path) ?? "")
    readonly property bool valid: /^#[0-9a-fA-F]{6,8}$/.test(val)
    spacing: Theme.px(8)
    Rectangle {
        implicitWidth: Theme.px(28); implicitHeight: implicitWidth; radius: width / 2
        color: r.valid ? r.val : "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.3)
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Settings.pickColor({ title: r.row.label, current: r.valid ? r.val : "#888888", pick: v => Settings.setPath(r.row.path, v) })
        }
    }
    Rectangle {
        implicitWidth: Theme.px(110); implicitHeight: Theme.px(30)
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
            onEditingFinished: if (/^#[0-9a-fA-F]{6,8}$/.test(text) && text !== r.val) Settings.setPath(r.row.path, text)
        }
    }
}

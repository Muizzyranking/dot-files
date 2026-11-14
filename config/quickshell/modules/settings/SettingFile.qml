import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// A file or folder. Type a path, or press the button to browse.
RowLayout {
    id: r
    required property var row
    readonly property string val: String(Settings.get(row.path) ?? "")
    readonly property bool isDir: row.spec.kind === "dir"
    spacing: Theme.px(6)
    Rectangle {
        implicitWidth: Theme.px(310); implicitHeight: Theme.px(30)
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
            Text {
                visible: ti.text === ""
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: r.row.hint ? "File default: " + r.row.hint : (r.row.spec.emptyLabel ?? "Not set")
                color: Theme.textFaint
                font: ti.font
                elide: Text.ElideRight
            }
        }
    }
    IconButton {
        name: r.isDir ? "folder_open" : "image"
        onClicked: Settings.pickPath({ dir: r.isDir, current: r.val, title: r.row.label, pick: v => Settings.setPath(r.row.path, v) })
    }
    IconButton { visible: r.val !== "" && r.row.spec.empty === true; name: "close"; onClicked: Settings.setPath(r.row.path, "") }
}

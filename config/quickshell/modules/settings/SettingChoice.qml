import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Pick from a list (installed fonts, cursor themes, colour names, monitors, ...).
RowLayout {
    id: r
    required property var row
    readonly property var spec: row.spec
    readonly property string val: String(Settings.get(row.path) ?? "")
    spacing: Theme.px(6)
    Rectangle {
        implicitWidth: Theme.px(270); implicitHeight: Theme.px(30)
        radius: Theme.px(8)
        color: Theme.surface
        border.width: hov.hovered ? 1 : 0
        border.color: Theme.accent
        HoverHandler { id: hov }
        RowLayout {
            anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(8) }
            Rectangle {
                visible: r.spec.choices === "colorname" && r.val !== ""
                implicitWidth: Theme.px(16); implicitHeight: implicitWidth; radius: width / 2
                color: Config.v.colors[r.val] ?? r.val
                border.width: 1; border.color: Qt.alpha(Theme.text, 0.25)
            }
            Label {
                Layout.fillWidth: true
                text: r.val !== "" ? r.val : (r.spec.emptyLabel ?? "Default")
                color: r.val !== "" ? Theme.text : Theme.textFaint
                font.family: r.spec.choices === "font" && r.val !== "" ? r.val : Theme.fontFamily
                elide: Text.ElideRight
            }
            Icon { name: "unfold_more"; size: Theme.px(16); color: Theme.textDim }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Installed.ensure(r.spec.choices)
                Settings.choose({ title: r.row.label, spec: r.spec, current: r.val, pick: v => Settings.setPath(r.row.path, v) })
            }
        }
    }
    IconButton { visible: r.val !== "" && r.spec.empty === true; name: "close"; onClicked: Settings.setPath(r.row.path, "") }
}

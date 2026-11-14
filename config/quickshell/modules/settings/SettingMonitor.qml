import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

// Pick monitors by clicking them. For "include", none selected means all monitors.
RowLayout {
    id: r
    required property var row
    readonly property var arr: Settings.get(row.path) ?? []
    spacing: Theme.px(6)
    Repeater {
        model: Array.from(Quickshell.screens).map(s => s.name)
        delegate: Rectangle {
            id: chip
            required property string modelData
            readonly property bool on: r.arr.includes(modelData)
            implicitHeight: Theme.px(28)
            implicitWidth: lb.implicitWidth + Theme.px(24)
            radius: height / 2
            color: on ? Theme.accent : mh.hovered ? Theme.surfaceHi : Theme.surface
            HoverHandler { id: mh }
            Label { id: lb; anchors.centerIn: parent; text: chip.modelData; color: chip.on ? Theme.accentText : Theme.text }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.setPath(r.row.path, chip.on ? r.arr.filter(x => x !== chip.modelData) : r.arr.concat([chip.modelData]))
            }
        }
    }
    Label { visible: r.arr.length === 0; text: "all"; color: Theme.textFaint }
}

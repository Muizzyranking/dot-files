import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Pick one of a fixed set of values with the arrows.
RowLayout {
    id: r
    required property var row
    readonly property var opts: Settings.options(row.path) ?? []
    readonly property string val: String(Settings.get(row.path) ?? "")
    function go(d) {
        if (opts.length === 0) return
        const i = opts.indexOf(val)
        Settings.setPath(row.path, opts[((i < 0 ? 0 : i) + d + opts.length) % opts.length])
    }
    spacing: Theme.px(2)
    IconButton { name: "chevron_left"; onClicked: r.go(-1) }
    Rectangle {
        implicitWidth: Theme.px(170); implicitHeight: Theme.px(30)
        radius: Theme.px(8)
        color: Theme.surface
        Label { anchors.centerIn: parent; width: parent.width - Theme.px(16); horizontalAlignment: Text.AlignHCenter; text: r.val; elide: Text.ElideRight }
    }
    IconButton { name: "chevron_right"; onClicked: r.go(1) }
}

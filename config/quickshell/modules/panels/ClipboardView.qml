import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Clipboard history. Click an entry to copy it again.
ColumnLayout {
    id: root
    property real listMax: Theme.px(190)
    signal picked()
    spacing: Theme.px(8)
    Component.onCompleted: Clip.refresh()

    PanelHeader {
        icon: "content_paste"
        title: "Clipboard"
        IconButton { visible: Clip.items.length > 0; name: "delete_sweep"; onClicked: Clip.wipe() }
    }
    Label {
        visible: Clip.items.length === 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Nothing here yet. History needs cliphist and a wl-paste watcher (see config.md)."
        color: Theme.textDim
        font.pixelSize: Theme.fontSize - 1
    }
    ListView {
        visible: Clip.items.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.min(contentHeight, root.listMax) : 0
        clip: true
        spacing: 2
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: Clip.items
        delegate: Rectangle {
            id: d
            required property var modelData
            width: ListView.view.width
            height: Theme.px(32)
            radius: Theme.px(10)
            color: hov.hovered ? Theme.surface : "transparent"
            HoverHandler { id: hov }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { Clip.copy(d.modelData.id); root.picked() }
            }
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(4) }
                spacing: Theme.px(8)
                Label {
                    Layout.fillWidth: true
                    text: d.modelData.text.startsWith("[[ binary") ? "Image" : d.modelData.text
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSize - 1
                }
                IconButton { name: "close"; onClicked: Clip.remove(d.modelData.id) }
            }
        }
    }
}

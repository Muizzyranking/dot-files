import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Clicked toast: the whole notification, with its actions. Dismiss removes it for good;
// otherwise it stays in the notifications panel.
ColumnLayout {
    id: root
    spacing: Theme.px(8)
    readonly property real pad: Theme.px(Config.v.panels.padding)

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: root.pad
        Layout.leftMargin: root.pad
        Layout.rightMargin: root.pad
        spacing: Theme.px(8)
        Item {
            implicitWidth: Theme.px(20); implicitHeight: Theme.px(20)
            IconImage { anchors.fill: parent; visible: Toasts.snap.icon !== ""; source: Toasts.snap.icon }
            Icon { anchors.centerIn: parent; visible: Toasts.snap.icon === ""; name: "notifications"; size: Theme.px(18); color: Theme.islandTextDim }
        }
        Label { Layout.fillWidth: true; text: Toasts.snap.appName; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
        IconButton { name: "close"; tone: Theme.islandText; onClicked: Toasts.dismissCurrent() }
    }
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: root.pad
        Layout.rightMargin: root.pad
        visible: Toasts.snap.summary !== ""
        text: Toasts.snap.summary
        color: Theme.islandText
        font.weight: Font.DemiBold
        font.pixelSize: Theme.fontSize + 1
        wrapMode: Text.Wrap
    }
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: root.pad
        Layout.rightMargin: root.pad
        visible: Toasts.snap.body !== ""
        text: Toasts.snap.body
        textFormat: Text.StyledText
        color: Theme.islandTextDim
        wrapMode: Text.Wrap
        maximumLineCount: Config.v.toasts.maxBodyLines
        elide: Text.ElideRight
    }
    RowLayout {
        visible: Toasts.current !== null && Toasts.current.actions.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: root.pad
        Layout.rightMargin: root.pad
        spacing: Theme.px(6)
        Repeater {
            model: Toasts.current ? Toasts.current.actions : []
            delegate: Chip {
                required property var modelData
                text: modelData.text
                onClicked: { modelData.invoke(); Toasts.clear() }
            }
        }
    }
    Item { implicitHeight: root.pad - Theme.px(8) }
}

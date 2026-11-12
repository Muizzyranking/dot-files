import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Toast: a wide, short snippet. Who it is from, and the first line of what it says.
Item {
    RowLayout {
        anchors { fill: parent; leftMargin: Theme.px(14); rightMargin: Theme.px(14) }
        spacing: Theme.px(10)
        Item {
            implicitWidth: Theme.px(24); implicitHeight: Theme.px(24)
            IconImage { anchors.fill: parent; visible: Toasts.snap.icon !== ""; source: Toasts.snap.icon }
            Icon { anchors.centerIn: parent; visible: Toasts.snap.icon === ""; name: "notifications"; size: Theme.px(18); color: Theme.islandTextDim }
        }
        Label {
            Layout.maximumWidth: Theme.px(150)
            text: Toasts.snap.appName
            color: Theme.islandTextDim
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            text: Toasts.snap.summary + (Toasts.snap.body !== "" ? "  ·  " + Toasts.snap.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ") : "")
            color: Theme.islandText
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}

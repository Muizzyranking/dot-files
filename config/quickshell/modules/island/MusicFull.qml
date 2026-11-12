import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Expanded music: art, title/artist, equalizer, progress and controls.
Item {
    id: root
    readonly property var p: Media.islandPlayer
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    Timer {
        running: root.p !== null && root.p.isPlaying
        repeat: true; interval: 1000
        onTriggered: root.p.positionChanged()
    }

    RowLayout {
        anchors { fill: parent; margins: Theme.px(Config.v.panels.padding) }
        spacing: Theme.px(14)

        ClippingRectangle {
            implicitWidth: Theme.px(88); implicitHeight: Theme.px(88)
            radius: Theme.px(16)
            color: Theme.surface
            Image {
                anchors.fill: parent
                source: root.p ? root.p.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 176
                sourceSize.height: 176
                visible: status === Image.Ready
            }
            Icon { anchors.centerIn: parent; name: "music_note"; size: Theme.px(28); color: Theme.textFaint }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.px(4)
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.px(8)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Marquee { Layout.fillWidth: true; implicitHeight: Theme.px(20); alignment: Qt.AlignLeft; text: root.p ? root.p.trackTitle : ""; color: Theme.islandText; pixelSize: Theme.fontSize + 1 }
                    Label { Layout.fillWidth: true; text: root.p ? root.p.trackArtist : ""; color: Theme.islandTextDim; elide: Text.ElideRight; font.pixelSize: Theme.fontSize - 1 }
                }
                Bars { count: 5; running: Media.active; tone: Theme.islandText }
            }
            Slider {
                Layout.fillWidth: true
                thickness: Theme.px(5)
                value: root.p && root.p.length > 0 ? root.p.position / root.p.length : 0
                onMoved: v => { if (root.p && root.p.canSeek) root.p.position = v * root.p.length }
            }
            RowLayout {
                Layout.fillWidth: true
                Label { text: root.p ? root.fmt(root.p.position) : ""; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 2 }
                Item { Layout.fillWidth: true }
                IconButton { tone: Theme.islandText; name: "skip_previous"; onClicked: root.p.previous() }
                Rectangle {
                    implicitWidth: Theme.px(34); implicitHeight: implicitWidth; radius: width / 2
                    color: Theme.accent
                    Icon { anchors.centerIn: parent; name: root.p && root.p.isPlaying ? "pause" : "play_arrow"; size: Theme.px(20); color: Theme.accentText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.p.togglePlaying() }
                }
                IconButton { tone: Theme.islandText; name: "skip_next"; onClicked: root.p.next() }
                Item { Layout.fillWidth: true }
                Label { text: root.p ? root.fmt(root.p.length) : ""; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 2 }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Idle-sized island while music plays: equalizer bars + slowly scrolling "Title · Artist".
Item {
    readonly property var p: Media.islandPlayer
    RowLayout {
        anchors {
            fill: parent
            leftMargin: Theme.px(12)
            rightMargin: Capture.recording ? Theme.px(26) : Theme.px(12)
        }
        spacing: Theme.px(8)
        Bars { Layout.alignment: Qt.AlignVCenter; running: Media.active; tone: Theme.islandText }
        Marquee {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.islandText
            pixelSize: Theme.fontSize - 1
            text: p ? (p.trackTitle + (p.trackArtist ? "  ·  " + p.trackArtist : "")) : ""
        }
    }
}

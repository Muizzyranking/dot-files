import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root

    property string stamp: ""          // formatted time
    property string dateStamp: ""      // formatted date, "" hides the line
    property real size: 100            // already Theme.px()-scaled
    property color tone: Theme.text    // date, minutes and suffix
    property color hoursTone: tone
    property bool shadow: true
    // 0 keeps the lock-screen ratio (date ≈ 15% of the time size)
    property real dateSize: size * 0.15

    spacing: Theme.px(2)
    readonly property var parts: stamp.match(/^(\d+)(\D+?)(\d+)(.*)$/)
    // what follows the minutes: ":ss" when seconds are on, "PM" on 12h clocks
    readonly property var tail: parts && parts[4] !== "" ? parts[4].match(/^(\s*:\d+)?\s*(.*)$/) : null
    readonly property string secs: tail && tail[1] ? tail[1].trim() : ""
    readonly property string ap: tail && tail[2] ? tail[2].trim() : ""
    readonly property real spacingPx: size * 0.03

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.dateStamp !== ""
        text: root.dateStamp
        color: root.tone
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(root.dateSize)
        font.weight: Font.Bold
        font.letterSpacing: root.dateSize * 0.25
        style: root.shadow ? Text.Raised : Text.Normal
        styleColor: Qt.rgba(0, 0, 0, 0.4)
    }
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.px(4)
        implicitWidth: hh.implicitWidth + mm.implicitWidth + ap.implicitWidth
            + root.spacingPx * ((mm.visible ? 1 : 0) + (ap.visible ? 1 : 0))
        implicitHeight: hh.implicitHeight

        Text {
            id: hh
            text: root.parts ? root.parts[1] : root.stamp
            color: root.hoursTone
            font.family: Theme.fontFamily
            font.pixelSize: root.size
            font.weight: Font.Black
            style: root.shadow ? Text.Raised : Text.Normal
            styleColor: Qt.rgba(0, 0, 0, 0.4)
        }
        Text {
            id: mm
            anchors.left: hh.right
            anchors.leftMargin: root.spacingPx
            anchors.baseline: hh.baseline
            visible: root.parts !== null
            text: root.parts ? root.parts[2].trim() + root.parts[3] + root.secs : ""
            color: root.tone
            font.family: Theme.fontFamily
            font.pixelSize: root.size
            font.weight: Font.Thin
            style: root.shadow ? Text.Raised : Text.Normal
            styleColor: Qt.rgba(0, 0, 0, 0.4)
        }
        Text {
            id: ap
            anchors.left: mm.right
            anchors.leftMargin: root.spacingPx
            anchors.baseline: hh.baseline
            visible: root.ap !== ""
            text: root.ap
            color: root.tone
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(root.size * 0.2)
            font.weight: Font.DemiBold
        }
    }
}

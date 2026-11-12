import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services

ClippingRectangle {
    id: root
    property real size: Theme.px(46)
    readonly property string nameText: Config.v.profile.name || SysInfo.host || "?"
    readonly property string path: (Config.v.profile.avatar || "").replace(/^~/, Quickshell.env("HOME"))
    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Theme.accent
    Image {
        id: img
        anchors.fill: parent
        visible: status === Image.Ready
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        source: root.path !== "" ? "file://" + root.path : ""
    }
    Text {
        visible: img.status !== Image.Ready
        anchors.centerIn: parent
        text: root.nameText.charAt(0).toUpperCase()
        color: Theme.accentText
        font.family: Theme.fontFamily
        font.pixelSize: root.size * 0.45
        font.weight: Font.Bold
    }
}

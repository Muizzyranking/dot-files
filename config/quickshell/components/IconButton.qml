import QtQuick
import qs.core

// A clickable icon with a soft hover highlight. Lives inside pills.
Item {
    id: root
    property string name: ""
    property color tone: Theme.text
    signal clicked(var mouse)
    signal wheel(var wheel)
    function centerX() { return mapToItem(null, width / 2, 0).x }

    implicitWidth: Theme.px(24)
    implicitHeight: Theme.px(22)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHi
        opacity: area.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Config.v.animation.fast } }
    }
    Icon { anchors.centerIn: parent; name: root.name; color: root.tone }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: w => root.wheel(w)
    }
}

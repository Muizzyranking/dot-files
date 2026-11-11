import QtQuick
import qs.core

Item {
    id: root
    property bool checked: false
    signal toggled()
    implicitWidth: Theme.px(34)
    implicitHeight: Theme.px(20)
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surfaceHi
        Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }
        Rectangle {
            width: parent.height - 6; height: width; radius: width / 2; y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.accentText : Theme.textDim
            Behavior on x { NumberAnimation { duration: Config.v.animation.fast; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
}

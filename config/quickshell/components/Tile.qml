import QtQuick
import QtQuick.Layouts
import qs.core

// Quick-setting tile. Left click = clicked(mouse) with Qt.LeftButton, right click likewise.
Rectangle {
    id: root
    property string icon: ""
    property string title: ""
    property string sub: ""
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    signal clicked(var mouse)
    implicitHeight: Theme.px(54)
    radius: Theme.px(16)
    color: active ? Theme.accent : area.containsMouse ? Theme.surfaceHi : Theme.surface
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }

    RowLayout {
        anchors { fill: parent; margins: Theme.px(12) }
        spacing: Theme.px(10)
        Icon { name: root.icon; color: root.active ? Theme.accentText : Theme.text }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { Layout.fillWidth: true; text: root.title; elide: Text.ElideRight; color: root.active ? Theme.accentText : Theme.text }
            Label {
                Layout.fillWidth: true
                visible: root.sub !== ""
                text: root.sub
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - 2
                color: root.active ? Qt.alpha(Theme.accentText, 0.7) : Theme.textDim
            }
        }
    }
    Icon {
        visible: root.expandable
        anchors { right: parent.right; rightMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
        name: root.expanded ? "expand_less" : "expand_more"
        size: Theme.px(14)
        color: root.active ? Theme.accentText : Theme.textDim
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => root.clicked(m)
    }
}

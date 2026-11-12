import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property string sub: ""
    property bool active: false
    signal clicked()
    implicitHeight: Theme.px(34)
    radius: Theme.px(10)
    color: area.containsMouse ? Theme.surfaceHi : "transparent"
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
        spacing: Theme.px(10)
        Icon { visible: root.icon !== ""; name: root.icon; color: root.active ? Theme.accent : Theme.textDim }
        Label { text: root.text; Layout.fillWidth: true; elide: Text.ElideRight }
        Label { visible: root.sub !== ""; text: root.sub; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
        Icon { visible: root.active; name: "check"; size: Theme.px(14); color: Theme.accent }
    }
    MouseArea { id: area; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: root.clicked() }
}

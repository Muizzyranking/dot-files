import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property bool danger: false
    property bool active: false
    signal clicked()
    implicitHeight: Theme.px(58)
    radius: Theme.px(14)
    color: danger ? Theme.bad : active ? Theme.accent : area.containsMouse ? Theme.surfaceHi : Theme.surface
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        Icon { Layout.alignment: Qt.AlignHCenter; name: root.icon; color: root.danger || root.active ? Theme.accentText : Theme.text }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            font.pixelSize: Theme.fontSize - 2
            color: root.danger || root.active ? Theme.accentText : Theme.text
        }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}

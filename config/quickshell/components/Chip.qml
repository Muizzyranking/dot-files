import QtQuick
import QtQuick.Layouts
import qs.core

// Small action pill used in expanded list rows.
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property bool danger: false
    signal clicked()
    implicitHeight: Theme.px(26)
    implicitWidth: row.implicitWidth + Theme.px(20)
    radius: Theme.px(9)
    color: area.containsMouse ? (danger ? Theme.bad : Theme.accent) : Theme.surfaceHi
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(5)
        Icon { visible: root.icon !== ""; name: root.icon; size: Theme.px(14); color: area.containsMouse ? Theme.accentText : root.danger ? Theme.bad : Theme.text }
        Label { text: root.text; font.pixelSize: Theme.fontSize - 1; color: area.containsMouse ? Theme.accentText : root.danger ? Theme.bad : Theme.text }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}

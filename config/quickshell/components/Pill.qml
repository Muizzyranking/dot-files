import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root
    default property alias content: row.data
    property bool clickable: false
    property real padding: Theme.px(Config.v.bar.pill.padding)
    property alias spacing: row.spacing
    signal clicked(var mouse)

    implicitHeight: Theme.px(Config.v.bar.pill.height)
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    border.width: Config.v.bar.pill.border
    border.color: Qt.alpha(Theme.text, 0.06)
    color: Qt.alpha(clickable && area.containsMouse ? Theme.surfaceHi : Theme.surface, Config.v.bar.pill.opacity)
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(Config.v.bar.pill.spacing)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.clickable
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}

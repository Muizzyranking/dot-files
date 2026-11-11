import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root
    property alias text: input.text
    property string placeholder: "Search"
    signal up()
    signal down()
    signal accepted()
    signal next()
    signal prev()
    function focusInput() { input.forceActiveFocus() }
    implicitHeight: Theme.px(32)
    radius: Theme.px(10)
    color: Theme.surface
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(6) }
        spacing: Theme.px(8)
        Icon { name: "search"; size: Theme.px(14); color: Theme.textDim }
        TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            clip: true
            Keys.onUpPressed: root.up()
            Keys.onDownPressed: root.down()
            Keys.onTabPressed: root.next()
            Keys.onBacktabPressed: root.prev()
            onAccepted: root.accepted()
            Text {
                visible: input.text === ""
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: root.placeholder
                color: Theme.textFaint
                font: input.font
            }
        }
        IconButton { visible: input.text !== ""; name: "close"; onClicked: input.text = "" }
    }
}

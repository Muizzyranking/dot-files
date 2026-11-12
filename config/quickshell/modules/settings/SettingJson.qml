import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Anything more complex (lists of objects, such as theming targets) as JSON text.
// A change is only saved when the text is valid JSON.
Rectangle {
    id: r
    required property var row
    readonly property string txt: JSON.stringify(Settings.get(row.path) ?? null)
    property bool bad: false
    implicitWidth: Theme.px(300); implicitHeight: Theme.px(30)
    radius: Theme.px(8)
    color: Theme.surface
    border.width: bad || ti.activeFocus ? 1 : 0
    border.color: bad ? Theme.bad : Theme.accent
    TextInput {
        id: ti
        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
        verticalAlignment: Text.AlignVCenter
        text: r.txt
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        selectByMouse: true
        clip: true
        onTextEdited: { try { JSON.parse(text); r.bad = false } catch (e) { r.bad = true } }
        onEditingFinished: {
            try { const v = JSON.parse(text); r.bad = false; if (text !== r.txt) Settings.setPath(r.row.path, v) }
            catch (e) { r.bad = true }
        }
    }
}

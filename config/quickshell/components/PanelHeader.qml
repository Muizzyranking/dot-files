import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    property string icon: ""
    property string title: ""
    default property alias trailing: tr.data
    Layout.fillWidth: true
    spacing: Theme.px(8)
    Icon { name: root.icon; color: Theme.accent }
    Label { text: root.title; font.weight: Font.DemiBold; Layout.fillWidth: true }
    RowLayout { id: tr; spacing: Theme.px(8) }
}

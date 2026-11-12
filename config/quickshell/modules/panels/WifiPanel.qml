import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    property real panelWidth: Theme.px(Config.v.panels.networkWidth)
    WifiView { Layout.fillWidth: true }
}

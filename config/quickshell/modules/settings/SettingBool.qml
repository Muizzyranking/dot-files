import QtQuick
import qs.components
import qs.services

Toggle {
    required property var row
    checked: Settings.get(row.path) === true
    onToggled: Settings.setPath(row.path, !checked)
}

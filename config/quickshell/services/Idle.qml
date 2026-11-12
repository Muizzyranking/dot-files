pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property bool active: false
    function toggle() { active = !active }
}

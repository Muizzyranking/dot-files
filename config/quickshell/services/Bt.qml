pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root
    readonly property bool available: Bluetooth.defaultAdapter !== null
    readonly property bool enabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    property int connected: 0

    function toggle() { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }

    function recount() {
        const list = Bluetooth.devices ? Array.from(Bluetooth.devices.values) : []
        connected = list.filter(d => d.connected).length
    }
    Timer { running: true; repeat: true; triggeredOnStart: true; interval: 3000; onTriggered: root.recount() }

    readonly property string icon: !enabled ? "bluetooth_disabled"
                                 : connected > 0 ? "bluetooth_connected" : "bluetooth"
}

pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.core

Singleton {
    id: root
    property bool muted: false
    property bool armed: false          // stays false for 3s after start so boot doesn't beep
    readonly property bool enabled: Config.v.sounds.enabled && !muted

    function init() {}

    function play(path) {
        if (!enabled || !armed || !path) return
        player.command = ["paplay", "--volume=" + Math.round(Config.v.sounds.volume * 65536), path]
        player.running = true
    }

    function notify(urgent) { if (urgent || !Notifs.dnd) play(Config.v.sounds.notification) }

    Process { id: player }
    Timer { running: true; interval: 3000; onTriggered: root.armed = true }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.play(UPower.onBattery ? Config.v.sounds.chargerUnplug : Config.v.sounds.chargerPlug)
        }
    }
    Connections {
        target: Battery
        function onPercentChanged() {
            if (!Battery.plugged && Battery.present && Battery.percent === Config.v.battery.low)
                root.play(Config.v.sounds.lowBattery)
        }
    }

    // USB devices (one event per device, not per interface)
    property string usbEvent: ""
    Timer {
        id: usbDebounce
        interval: 500
        onTriggered: {
            root.play(root.usbEvent === "add" ? Config.v.sounds.usbAdd : Config.v.sounds.usbRemove)
            root.usbEvent = ""
        }
    }
    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=usb/usb_device"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/\s(add|remove)\s/)
                if (!m) return
                root.usbEvent = m[1]
                usbDebounce.restart()
            }
        }
    }
}

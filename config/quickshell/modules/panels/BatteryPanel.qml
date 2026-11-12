import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.core
import qs.components
import qs.services

ColumnLayout {
    id: root
    property real panelWidth: Theme.px(Config.v.panels.width)
    spacing: Theme.px(10)
    readonly property var dev: UPower.displayDevice
    Component.onCompleted: Battery.refreshHealth()

    function fmt(sec) {
        if (!sec || sec <= 0) return ""
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }
    readonly property string status: {
        if (!Battery.present) return "No battery detected"
        if (dev.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (dev.state === UPowerDeviceState.Charging) return fmt(dev.timeToFull) ? fmt(dev.timeToFull) + " until full" : "Charging"
        return fmt(dev.timeToEmpty) ? fmt(dev.timeToEmpty) + " remaining" : "On battery"
    }
    readonly property color healthTone: Battery.health >= 80 ? Theme.good : Battery.health >= 60 ? Theme.warn : Theme.bad

    PanelHeader { icon: Battery.plugged ? "battery_charging_full" : "battery_full"; title: "Battery" }

    RowLayout {
        visible: Battery.present
        Layout.fillWidth: true
        Label { text: Battery.percent + "%"; font.pixelSize: Theme.px(30); font.weight: Font.DemiBold }
        Item { Layout.fillWidth: true }
        Label { text: root.status; color: Theme.textDim }
    }
    Label { visible: !Battery.present; text: root.status; color: Theme.textDim }

    // ---- health ----
    ColumnLayout {
        visible: Battery.health >= 0
        Layout.fillWidth: true
        spacing: Theme.px(8)
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Battery health"; Layout.fillWidth: true }
            Label { text: Math.round(Battery.health) + "%"; color: root.healthTone; font.weight: Font.DemiBold }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.px(6); radius: height / 2; color: Theme.surfaceHi
            Rectangle { width: parent.width * Math.min(100, Battery.health) / 100; height: parent.height; radius: parent.radius; color: root.healthTone }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Theme.px(8)
            Repeater {
                model: [
                    { k: "Capacity", v: Battery.fullAmount.toFixed(Battery.unit === "Wh" ? 1 : 0) + " " + Battery.unit },
                    { k: "Designed", v: Battery.designAmount.toFixed(Battery.unit === "Wh" ? 1 : 0) + " " + Battery.unit },
                    { k: "Cycles", v: Battery.cycles >= 0 ? String(Battery.cycles) : "n/a" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    implicitHeight: Theme.px(46); radius: Theme.px(12); color: Theme.surface
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        Label { Layout.alignment: Qt.AlignHCenter; text: modelData.v; font.weight: Font.DemiBold }
                        Label { Layout.alignment: Qt.AlignHCenter; text: modelData.k; color: Theme.textDim; font.pixelSize: Theme.fontSize - 2 }
                    }
                }
            }
        }
        Label {
            visible: Battery.drawW > 0
            text: (Battery.plugged ? "Charging at " : "Drawing ") + Battery.drawW.toFixed(1) + " W"
            color: Theme.textDim; font.pixelSize: Theme.fontSize - 1
        }
    }
    Label { visible: Battery.present && Battery.health < 0; text: "Health data is not available for this battery"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }

    Label { text: "Power mode"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(6)
        Repeater {
            model: [
                { name: "Saver", icon: "eco", p: PowerProfile.PowerSaver, show: true },
                { name: "Balanced", icon: "balance", p: PowerProfile.Balanced, show: true },
                { name: "Performance", icon: "speed", p: PowerProfile.Performance, show: PowerProfiles.hasPerformanceProfile }
            ].filter(m => m.show)
            delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                icon: modelData.icon
                text: modelData.name
                active: PowerProfiles.profile === modelData.p
                onClicked: PowerProfiles.profile = modelData.p
            }
        }
    }
}

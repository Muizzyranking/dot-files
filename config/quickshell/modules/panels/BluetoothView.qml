import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.core
import qs.components

// Bluetooth controls. Used by the standalone panel and inside the control center.
ColumnLayout {
    id: root
    property real listMax: Theme.px(238)
    property string openAddr: ""
    spacing: Theme.px(8)
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter ? adapter.enabled : false
    readonly property var devices: Bluetooth.devices
        ? Array.from(Bluetooth.devices.values).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        : []

    PanelHeader {
        icon: root.on ? "bluetooth" : "bluetooth_disabled"
        title: "Bluetooth"
        IconButton {
            visible: root.on
            name: root.adapter && root.adapter.discovering ? "bluetooth_searching" : "search"
            tone: root.adapter && root.adapter.discovering ? Theme.accent : Theme.text
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }
        Toggle { visible: root.adapter !== null; checked: root.on; onToggled: root.adapter.enabled = !root.adapter.enabled }
    }
    Label {
        visible: !root.adapter || !root.on
        text: !root.adapter ? "No Bluetooth adapter found" : "Bluetooth is off"
        color: Theme.textDim
    }
    Label { visible: root.on && root.devices.length === 0; text: "No devices yet. Press search to scan."; color: Theme.textDim }

    ListView {
        visible: root.on && root.devices.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.min(contentHeight, root.listMax) : 0
        clip: true
        spacing: 2
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: root.devices

        delegate: Rectangle {
            id: d
            required property var modelData
            readonly property bool open: root.openAddr === modelData.address
            readonly property string battery: modelData.batteryAvailable
                ? Math.round(modelData.battery <= 1 ? modelData.battery * 100 : modelData.battery) + "%" : ""
            width: ListView.view.width
            height: col.implicitHeight
            radius: Theme.px(10)
            color: open || hov.hovered ? Theme.surface : "transparent"
            HoverHandler { id: hov }

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Theme.px(34)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (d.modelData.connected) d.modelData.disconnect()
                            else if (!d.modelData.paired) d.modelData.pair()
                            else d.modelData.connect()
                        }
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(4) }
                        spacing: Theme.px(10)
                        Icon { name: d.modelData.connected ? "bluetooth_connected" : "bluetooth"; color: d.modelData.connected ? Theme.accent : Theme.textDim }
                        Label { Layout.fillWidth: true; text: d.modelData.name; elide: Text.ElideRight }
                        Label {
                            text: d.modelData.connected ? (d.battery !== "" ? d.battery : "Connected") : d.modelData.paired ? "Paired" : ""
                            color: Theme.textDim; font.pixelSize: Theme.fontSize - 1
                        }
                        Icon { visible: d.modelData.connected; name: "check"; size: Theme.px(14); color: Theme.accent }
                        IconButton { name: "more_vert"; onClicked: root.openAddr = d.open ? "" : d.modelData.address }
                    }
                }
                ColumnLayout {
                    visible: d.open
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.px(10)
                    Layout.rightMargin: Theme.px(10)
                    Layout.bottomMargin: Theme.px(10)
                    spacing: Theme.px(6)
                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.px(6)
                        Chip {
                            text: d.modelData.connected ? "Disconnect" : "Connect"
                            icon: d.modelData.connected ? "link_off" : "link"
                            onClicked: d.modelData.connected ? d.modelData.disconnect() : d.modelData.connect()
                        }
                        Chip { visible: !d.modelData.paired; text: "Pair"; icon: "add_link"; onClicked: d.modelData.pair() }
                        Chip {
                            visible: d.modelData.paired
                            text: d.modelData.trusted ? "Untrust" : "Trust"
                            icon: "verified_user"
                            onClicked: d.modelData.trusted = !d.modelData.trusted
                        }
                        Chip { visible: d.modelData.paired; text: "Forget"; icon: "delete"; danger: true; onClicked: { d.modelData.forget(); root.openAddr = "" } }
                    }
                    Repeater {
                        model: [
                            ["Address", d.modelData.address],
                            ["Status", d.modelData.connected ? "Connected" : d.modelData.paired ? "Paired" : "Not paired"],
                            ["Trusted", d.modelData.trusted ? "Yes" : "No"],
                            ["Battery", d.battery]
                        ].filter(r => r[1] !== "")
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Label { text: modelData[0]; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1; Layout.preferredWidth: Theme.px(80) }
                            Label { text: modelData[1]; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: Theme.fontSize - 1 }
                        }
                    }
                }
            }
        }
    }
}

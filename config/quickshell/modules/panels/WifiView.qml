import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Wi-Fi controls. Used by the standalone panel and inside the control center.
ColumnLayout {
    id: root
    property real listMax: Theme.px(238)
    property string openSsid: ""
    property string pwFor: ""
    spacing: Theme.px(8)

    Component.onCompleted: { Net.refresh(); Net.scan() }
    function submit() {
        if (pw.text === "") return
        Net.connectTo(root.pwFor, pw.text)
        pw.text = ""
        root.pwFor = ""
    }

    PanelHeader {
        icon: Net.icon
        title: "Wi-Fi"
        IconButton { visible: Net.wifiEnabled; name: "refresh"; onClicked: Net.scan() }
        Toggle { checked: Net.wifiEnabled; onToggled: Net.setEnabled(!Net.wifiEnabled) }
    }

    ListItem { visible: Net.ethernet; Layout.fillWidth: true; icon: "lan"; text: "Ethernet"; sub: "Connected"; active: true }
    Label { visible: !Net.wifiEnabled; text: "Wi-Fi is off"; color: Theme.textDim }
    Label { visible: Net.wifiEnabled && Net.networks.length === 0; text: "Looking for networks..."; color: Theme.textDim }

    ListView {
        visible: Net.wifiEnabled && Net.networks.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.min(contentHeight, root.listMax) : 0
        clip: true
        spacing: 2
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: Net.networks

        delegate: Rectangle {
            id: d
            required property var modelData
            readonly property bool open: root.openSsid === modelData.ssid
            readonly property bool saved: Net.saved.includes(modelData.ssid)
            readonly property var rows: {
                const r = [["Signal", modelData.signal + "%"], ["Security", modelData.secure ? modelData.security : "Open"]]
                if (modelData.chan) r.push(["Channel", modelData.chan + (modelData.freq ? "  ·  " + modelData.freq : "")])
                if (modelData.rate) r.push(["Speed", modelData.rate])
                if (modelData.bssid) r.push(["BSSID", modelData.bssid])
                if (modelData.active && Net.ipInfo.ip) {
                    r.push(["IP address", Net.ipInfo.ip])
                    if (Net.ipInfo.gateway) r.push(["Gateway", Net.ipInfo.gateway])
                    if (Net.ipInfo.dns) r.push(["DNS", Net.ipInfo.dns])
                }
                return r
            }
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
                            if (d.modelData.active) Net.disconnect()
                            else if (!d.modelData.secure || d.saved) Net.connectTo(d.modelData.ssid, "")
                            else root.pwFor = root.pwFor === d.modelData.ssid ? "" : d.modelData.ssid
                        }
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(4) }
                        spacing: Theme.px(10)
                        Icon { name: Net.signalIcon(d.modelData.signal); color: d.modelData.active ? Theme.accent : Theme.textDim }
                        Label { Layout.fillWidth: true; text: d.modelData.ssid; elide: Text.ElideRight }
                        Label {
                            text: d.modelData.active ? "Connected" : d.modelData.secure ? (d.saved ? "Saved" : "Secured") : "Open"
                            color: Theme.textDim; font.pixelSize: Theme.fontSize - 1
                        }
                        Icon { visible: d.modelData.active; name: "check"; size: Theme.px(14); color: Theme.accent }
                        IconButton {
                            name: "more_vert"
                            onClicked: {
                                if (!d.open && d.modelData.active) Net.loadInfo()
                                root.openSsid = d.open ? "" : d.modelData.ssid
                            }
                        }
                    }
                }
                ColumnLayout {
                    visible: d.open
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.px(10)
                    Layout.rightMargin: Theme.px(10)
                    Layout.bottomMargin: Theme.px(10)
                    spacing: Theme.px(6)
                    RowLayout {
                        spacing: Theme.px(6)
                        Chip {
                            text: d.modelData.active ? "Disconnect" : "Connect"
                            icon: d.modelData.active ? "wifi_off" : "wifi"
                            onClicked: {
                                if (d.modelData.active) Net.disconnect()
                                else if (!d.modelData.secure || d.saved) Net.connectTo(d.modelData.ssid, "")
                                else root.pwFor = d.modelData.ssid
                            }
                        }
                        Chip { visible: d.saved; text: "Forget"; icon: "delete"; danger: true; onClicked: { Net.forget(d.modelData.ssid); root.openSsid = "" } }
                    }
                    Repeater {
                        model: d.rows
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

    Rectangle {
        visible: root.pwFor !== ""
        Layout.fillWidth: true
        implicitHeight: Theme.px(34)
        radius: Theme.px(10)
        color: Theme.surfaceHi
        onVisibleChanged: if (visible) pw.forceActiveFocus()
        TextInput {
            id: pw
            anchors { fill: parent; leftMargin: Theme.px(12); rightMargin: Theme.px(40) }
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            clip: true
            onAccepted: root.submit()
            Text {
                visible: pw.text === ""
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "Password for " + root.pwFor
                color: Theme.textFaint
                font: pw.font
                elide: Text.ElideRight
            }
        }
        IconButton {
            anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
            name: "arrow_forward"
            onClicked: root.submit()
        }
    }
    Label {
        visible: Net.pending !== "" || Net.error !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Net.pending !== "" ? "Connecting to " + Net.pending + "..." : Net.error
        color: Net.pending !== "" ? Theme.textDim : Theme.bad
        font.pixelSize: Theme.fontSize - 1
    }
}

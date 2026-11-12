import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

// Tabs: Memory and CPU show every process (search, scroll, kill).
// Swap and Disk show a gauge. The list pauses while the mouse is over it,
// so rows do not jump under your cursor.
ColumnLayout {
    id: root
    property real panelWidth: Theme.px(Config.v.panels.vitalsWidth)
    spacing: Theme.px(10)

    property int tab: 0                 // 0 memory, 1 cpu, 2 swap, 3 disk
    readonly property bool listTab: tab < 2
    property var rows: []
    property string armedPid: ""
    property var termed: ({})

    Component.onCompleted: { SysStats.watchProcs = true; refresh(true) }
    Component.onDestruction: SysStats.watchProcs = false
    onTabChanged: refresh(true)

    function fmtKb(kb) { return kb >= 1048576 ? (kb / 1048576).toFixed(1) + " GB" : Math.round(kb / 1024) + " MB" }
    function fmtB(b) { return b >= 1e12 ? (b / 1e12).toFixed(2) + " TB" : (b / 1e9).toFixed(1) + " GB" }
    function refresh(force) {
        if (!force && listHover.hovered) return
        const q = search.text.trim().toLowerCase()
        let r = SysStats.procs
        if (q) r = r.filter(p => p.name.toLowerCase().includes(q) || String(p.pid).includes(q))
        const key = tab === 0 ? "kb" : "cpu"
        rows = r.slice().sort((a, b) => b[key] - a[key]).slice(0, 250)
    }
    function pressKill(pid) {
        const k = String(pid)
        if (armedPid !== k) { armedPid = k; armTimer.restart(); return; }
        armedPid = ""
        SysStats.kill(pid, termed[pid] === true)
        const t = Object.assign({}, termed); t[pid] = true; termed = t
    }
    Timer { id: armTimer; interval: 3000; onTriggered: root.armedPid = "" }
    Connections { target: SysStats; function onProcsChanged() { root.refresh(false) } }

    PanelHeader { icon: "monitoring"; title: "System" }

    // segmented tabs with a sliding highlight
    Rectangle {
        id: tabs
        Layout.fillWidth: true
        implicitHeight: Theme.px(34)
        radius: Theme.px(12)
        color: Theme.surface
        Rectangle {
            y: 3; height: parent.height - 6
            width: parent.width / 4 - 6
            x: root.tab * (parent.width / 4) + 3
            radius: Theme.px(9)
            color: Theme.accent
            Behavior on x { NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
        }
        Row {
            anchors.fill: parent
            Repeater {
                model: [
                    { icon: "memory", name: "Memory" },
                    { icon: "developer_board", name: "CPU" },
                    { icon: "swap_vert", name: "Swap" },
                    { icon: "hard_drive", name: "Disk" }
                ]
                delegate: Item {
                    id: tb
                    required property var modelData
                    required property int index
                    width: tabs.width / 4; height: tabs.height
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.px(6)
                        Icon { name: tb.modelData.icon; size: Theme.px(15); color: root.tab === tb.index ? Theme.accentText : Theme.textDim }
                        Label { text: tb.modelData.name; color: root.tab === tb.index ? Theme.accentText : Theme.textDim }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.tab = tb.index }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.px(380)

        // Memory / CPU
        ColumnLayout {
            anchors.fill: parent
            visible: root.listTab
            spacing: Theme.px(10)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.px(66)
                radius: Theme.px(14)
                color: Theme.surface
                readonly property real pct: root.tab === 0 ? SysStats.memory : SysStats.cpu
                RowLayout {
                    anchors { fill: parent; margins: Theme.px(14) }
                    spacing: Theme.px(14)
                    ColumnLayout {
                        spacing: 0
                        Label {
                            text: Math.round(parent.parent.parent.pct) + "%"
                            font.pixelSize: Theme.px(24); font.weight: Font.DemiBold
                            color: Theme.vitalColor(parent.parent.parent.pct)
                        }
                        Label {
                            text: root.tab === 0 ? root.fmtKb(SysStats.memUsedKb) + " of " + root.fmtKb(SysStats.memTotalKb)
                                                 : SysStats.cores + " cores"
                            color: Theme.textDim; font.pixelSize: Theme.fontSize - 1
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.px(8); radius: height / 2; color: Theme.surfaceHi
                        Rectangle {
                            width: parent.width * Math.min(1, parent.parent.parent.parent.pct / 100)
                            height: parent.height; radius: parent.radius
                            color: Theme.vitalColor(parent.parent.parent.parent.pct)
                            Behavior on width { NumberAnimation { duration: Config.v.animation.normal } }
                        }
                    }
                }
            }

            SearchField {
                id: search
                Layout.fillWidth: true
                placeholder: "Search processes or PID"
                onTextChanged: root.refresh(true)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                HoverHandler { id: listHover }

                Label {
                    visible: root.rows.length === 0
                    anchors.centerIn: parent
                    text: SysStats.procs.length === 0 ? "Loading processes..." : "No matching processes"
                    color: Theme.textDim
                }
                ListView {
                    id: lv
                    anchors.fill: parent
                    anchors.rightMargin: Theme.px(8)
                    model: root.rows
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool armed: root.armedPid === String(modelData.pid)
                        readonly property bool termed: root.termed[modelData.pid] === true
                        width: ListView.view.width
                        height: Theme.px(34)
                        radius: Theme.px(10)
                        color: hh.hovered || armed ? Theme.surface : "transparent"
                        HoverHandler { id: hh }
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(6) }
                            spacing: Theme.px(8)
                            Label { text: row.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                            Label { text: row.modelData.pid; color: Theme.textFaint; font.pixelSize: Theme.fontSize - 2 }
                            Label {
                                Layout.preferredWidth: Theme.px(62)
                                horizontalAlignment: Text.AlignRight
                                text: root.tab === 0 ? root.fmtKb(row.modelData.kb) : row.modelData.cpu.toFixed(1) + "%"
                                color: Theme.textDim
                            }
                            Rectangle {
                                implicitWidth: row.armed ? Theme.px(56) : Theme.px(26)
                                implicitHeight: Theme.px(24)
                                radius: Theme.px(8)
                                color: row.armed ? Theme.bad : kh.hovered ? Theme.surfaceHi : "transparent"
                                Behavior on implicitWidth { NumberAnimation { duration: Config.v.animation.fast } }
                                HoverHandler { id: kh }
                                Icon { visible: !row.armed; anchors.centerIn: parent; name: "close"; size: Theme.px(14); color: kh.hovered ? Theme.bad : Theme.textFaint }
                                Label { visible: row.armed; anchors.centerIn: parent; text: row.termed ? "Force?" : "Kill?"; color: Theme.accentText; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pressKill(row.modelData.pid) }
                            }
                        }
                    }
                }
                Rectangle {
                    visible: lv.contentHeight > lv.height
                    anchors.right: parent.right
                    width: 3; radius: 1.5; color: Theme.textFaint
                    y: lv.visibleArea.yPosition * lv.height
                    height: Math.max(20, lv.visibleArea.heightRatio * lv.height)
                }
            }
        }

        // Swap / Disk gauges
        ColumnLayout {
            anchors.fill: parent
            visible: !root.listTab
            spacing: Theme.px(14)
            Item { Layout.fillHeight: true }
            Ring {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Theme.px(200)
                Layout.preferredHeight: Theme.px(200)
                value: root.tab === 2 ? SysStats.swap : SysStats.disk
                tone: Theme.vitalColor(value)
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(root.tab === 2 ? SysStats.swap : SysStats.disk) + "%"
                        font.pixelSize: Theme.px(34); font.weight: Font.DemiBold
                    }
                    Label { Layout.alignment: Qt.AlignHCenter; text: root.tab === 2 ? "swap used" : "disk used"; color: Theme.textDim }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.tab === 2
                    ? (SysStats.swapTotalKb > 0 ? root.fmtKb(SysStats.swapUsedKb) + " of " + root.fmtKb(SysStats.swapTotalKb) : "No swap configured")
                    : root.fmtB(SysStats.diskUsedB) + " of " + root.fmtB(SysStats.diskTotalB) + "  ( / )"
                color: Theme.textDim
            }
            Item { Layout.fillHeight: true }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services
import qs.modules.panels

// The island, expanded. Header (host, uptime, lock, power) then Quick / Media / About.
// Wi-Fi, Bluetooth, microphone, power mode, screenshot, recording and clipboard
// open a dropdown right inside this popup.
ColumnLayout {
    id: root
    spacing: Theme.px(12)
    property int tab: 0
    property string detail: ""
    property bool powerMenu: false
    property int armed: -1
    property string detailShown: ""
    onDetailChanged: if (detail !== "") detailShown = detail
    readonly property string nameText: Config.v.profile.name || SysInfo.host || "?"
    readonly property string avatarPath: (Config.v.profile.avatar || "").replace(/^~/, Quickshell.env("HOME"))

    readonly property var mic: Pipewire.defaultAudioSource
    readonly property bool micMuted: mic && mic.audio ? mic.audio.muted : false
    readonly property real micVol: mic && mic.audio ? mic.audio.volume : 0
    PwObjectTracker { objects: [root.mic] }

    function toggleDetail(n) { detail = detail === n ? "" : n }
    function done() { Panels.close(); IslandState.collapse() }
    function clock(s) { return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    Component.onCompleted: { Backlight.screen.refresh(); Backlight.keys.refresh(); SysInfo.refresh() }
    Timer { running: true; repeat: true; interval: 30000; onTriggered: SysInfo.refresh() }
    Timer { id: armTimer; interval: 3000; onTriggered: root.armed = -1 }

    component Detail: Rectangle {
        default property alias body: inner.data
        color: Theme.barBg
        radius: Theme.px(16)
        implicitHeight: inner.implicitHeight + Theme.px(24)
        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.px(12) }
            spacing: Theme.px(8)
        }
    }

    // header
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(12)
        Avatar { size: Theme.px(46) }
        ColumnLayout {
            spacing: 0
            Label { text: root.nameText; color: Theme.islandText; font.pixelSize: Theme.fontSize + 4; font.weight: Font.DemiBold }
            Label { text: "Up " + SysInfo.fmtUptime(SysInfo.uptimeSec); color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 1 }
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            implicitWidth: Theme.px(36); implicitHeight: implicitWidth; radius: width / 2
            color: lh.hovered ? Theme.surfaceHi : Theme.surface
            HoverHandler { id: lh }
            Icon { anchors.centerIn: parent; name: "lock" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Session.lock(); root.done() } }
        }
        Rectangle {
            implicitWidth: Theme.px(36); implicitHeight: implicitWidth; radius: width / 2
            color: root.powerMenu ? Theme.bad : ph.hovered ? Theme.surfaceHi : Theme.surface
            HoverHandler { id: ph }
            Icon { anchors.centerIn: parent; name: "power_settings_new"; color: root.powerMenu ? Theme.accentText : Theme.text }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.powerMenu = !root.powerMenu; root.armed = -1 } }
        }
    }

    // power menu
    Item {
        id: pm
        Layout.fillWidth: true
        property real rev: root.powerMenu ? 1 : 0
        Behavior on rev { NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
        visible: rev > 0.001
        clip: true
        implicitHeight: pmGrid.implicitHeight * rev
        GridLayout {
            id: pmGrid
            width: parent.width
            opacity: pm.rev
            columns: 3
            columnSpacing: Theme.px(8)
            rowSpacing: Theme.px(8)
            Repeater {
                model: [
                    { icon: "lock", name: "Lock", act: "lock", confirm: false },
                    { icon: "bedtime", name: "Suspend", act: "suspend", confirm: false },
                    { icon: "mode_night", name: "Hibernate", act: "hibernate", confirm: false },
                    { icon: "logout", name: "Log out", act: "logout", confirm: true },
                    { icon: "restart_alt", name: "Reboot", act: "reboot", confirm: true },
                    { icon: "power_settings_new", name: "Power off", act: "poweroff", confirm: true }
                ]
                delegate: ActionButton {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: modelData.icon
                    text: root.armed === index ? "Confirm?" : modelData.name
                    danger: root.armed === index
                    onClicked: {
                        if (modelData.confirm && root.armed !== index) { root.armed = index; armTimer.restart(); return; }
                        root.armed = -1
                        if (modelData.act === "lock") Session.lock()
                        else Session.run(Config.v.session[modelData.act])
                        root.done()
                    }
                }
            }
        }
    }

    Tabs {
        Layout.fillWidth: true
        model: [{ icon: "tune", name: "Quick" }, { icon: "music_note", name: "Media" }, { icon: "info", name: "About" }]
        current: root.tab
        onPicked: i => root.tab = i
    }

    Item {
        id: body
        Layout.fillWidth: true
        clip: true
        property bool tabAnim: false
        implicitHeight: bodyLoader.item ? bodyLoader.item.implicitHeight : 0
        Behavior on implicitHeight { enabled: body.tabAnim; NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
        Loader {
            id: bodyLoader
            width: parent.width
            sourceComponent: root.tab === 0 ? quickC : root.tab === 1 ? mediaC : aboutC
        }
        Connections { target: root; function onTabChanged() { body.tabAnim = true; tabT.restart() } }
        Timer { id: tabT; interval: Config.v.animation.normal + 40; onTriggered: body.tabAnim = false }
    }

    // ================= Quick =================
    Component {
        id: quickC
        ColumnLayout {
            spacing: Theme.px(12)

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Theme.px(8)
                rowSpacing: Theme.px(8)

                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Net.icon; title: "Wi-Fi"
                    sub: Net.wifiEnabled ? (Net.ssid || "Not connected") : "Off"
                    active: Net.wifiEnabled; expandable: true; expanded: root.detail === "wifi"
                    onClicked: m => m.button === Qt.RightButton ? Net.setEnabled(!Net.wifiEnabled) : root.toggleDetail("wifi")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Bt.icon; title: "Bluetooth"
                    sub: Bt.enabled ? (Bt.connected > 0 ? Bt.connected + " connected" : "On") : "Off"
                    active: Bt.enabled; expandable: true; expanded: root.detail === "bluetooth"
                    onClicked: m => m.button === Qt.RightButton ? Bt.toggle() : root.toggleDetail("bluetooth")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Notifs.dnd ? "notifications_off" : "notifications"; title: "Do not disturb"
                    sub: Notifs.dnd ? "On" : "Off"; active: Notifs.dnd
                    onClicked: Notifs.toggleDnd()
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Sounds.enabled ? "notifications_active" : "volume_off"; title: "Sounds"
                    sub: Sounds.enabled ? "On" : "Muted"; active: Sounds.enabled
                    onClicked: Sounds.muted = !Sounds.muted
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: PowerProfiles.profile === PowerProfile.Performance ? "speed"
                        : PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : "balance"
                    title: "Power mode"
                    sub: PowerProfiles.profile === PowerProfile.Performance ? "Performance"
                        : PowerProfiles.profile === PowerProfile.PowerSaver ? "Saver" : "Balanced"
                    active: PowerProfiles.profile !== PowerProfile.Balanced
                    expandable: true; expanded: root.detail === "power"
                    onClicked: root.toggleDetail("power")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: root.micMuted ? "mic_off" : "mic"; title: "Microphone"
                    sub: root.micMuted ? "Muted" : Math.round(root.micVol * 100) + "%"
                    active: !root.micMuted; expandable: true; expanded: root.detail === "mic"
                    onClicked: m => {
                        if (m.button === Qt.RightButton) { if (root.mic && root.mic.audio) root.mic.audio.muted = !root.micMuted }
                        else root.toggleDetail("mic")
                    }
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "screenshot_region"; title: "Screenshot"
                    expandable: true; expanded: root.detail === "shot"
                    onClicked: root.toggleDetail("shot")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Capture.recording ? "stop_circle" : "videocam"; title: "Screen record"
                    sub: Capture.recording ? "Recording " + root.clock(Capture.elapsed) : "Off"
                    active: Capture.recording; expandable: true; expanded: root.detail === "rec"
                    onClicked: root.toggleDetail("rec")
                }
                Tile {
                    visible: Config.v.modules.idleInhibitor
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "coffee"; title: "Keep awake"
                    sub: Idle.active ? "On" : "Off"; active: Idle.active
                    onClicked: Idle.toggle()
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "content_paste"; title: "Clipboard"
                    expandable: true; expanded: root.detail === "clip"
                    onClicked: root.toggleDetail("clip")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "wallpaper"; title: "Wallpaper"; sub: "Choose"
                    onClicked: { root.done(); Popups.toggle("wallpaper") }
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "palette"; title: "Palette"; sub: Theming.current
                    expandable: true; expanded: root.detail === "palette"
                    onClicked: root.toggleDetail("palette")
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "settings"; title: "Settings"; sub: "config.json"
                    onClicked: { root.done(); Popups.toggle("settings") }
                }
            }

            // inline dropdown
            Item {
                id: dd
                Layout.fillWidth: true
                property real rev: root.detail !== "" ? 1 : 0
                Behavior on rev { NumberAnimation { duration: Config.v.animation.normal; easing.type: Easing.OutCubic } }
                visible: rev > 0.001
                clip: true
                implicitHeight: (ddl.item ? ddl.item.implicitHeight : 0) * rev
                Loader {
                    id: ddl
                    width: parent.width
                    opacity: dd.rev
                    active: root.detail !== "" || dd.rev > 0.001
                    sourceComponent: root.detailShown === "wifi" ? wifiD
                        : root.detailShown === "bluetooth" ? btD
                        : root.detailShown === "mic" ? micD
                        : root.detailShown === "power" ? powerD
                        : root.detailShown === "shot" ? shotD
                        : root.detailShown === "rec" ? recD
                        : root.detailShown === "clip" ? clipD
                        : root.detailShown === "palette" ? palD : null
                }
            }

            // sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.px(10)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.px(10)
                    IconButton { name: Audio.icon; tone: Audio.muted ? Theme.islandTextDim : Theme.islandText; onClicked: Audio.toggleMute() }
                    Slider {
                        Layout.fillWidth: true
                        thickness: Theme.px(10)
                        value: Audio.volume / Config.v.audio.maxVolume
                        marker: Config.v.audio.maxVolume > 1 ? 1 / Config.v.audio.maxVolume : -1
                        tone: Audio.muted ? Theme.textFaint : Audio.volume > 1 ? Theme.warn : Theme.accent
                        onMoved: v => Audio.setVolume(v * Config.v.audio.maxVolume)
                    }
                    Label { Layout.preferredWidth: Theme.px(40); horizontalAlignment: Text.AlignRight; text: Math.round(Audio.volume * 100) + "%"; color: Audio.volume > 1 ? Theme.warn : Theme.islandTextDim }
                }
                RowLayout {
                    visible: Backlight.screen.available
                    Layout.fillWidth: true
                    spacing: Theme.px(10)
                    Item { implicitWidth: Theme.px(24); implicitHeight: Theme.px(22); Icon { anchors.centerIn: parent; name: "light_mode"; color: Theme.islandText } }
                    Slider { Layout.fillWidth: true; thickness: Theme.px(10); value: Backlight.screen.value; onMoved: v => Backlight.screen.set(v) }
                    Label { Layout.preferredWidth: Theme.px(40); horizontalAlignment: Text.AlignRight; text: Math.round(Backlight.screen.value * 100) + "%"; color: Theme.islandTextDim }
                }
                RowLayout {
                    visible: Backlight.keys.available
                    Layout.fillWidth: true
                    spacing: Theme.px(10)
                    Item { implicitWidth: Theme.px(24); implicitHeight: Theme.px(22); Icon { anchors.centerIn: parent; name: "keyboard"; color: Theme.islandText } }
                    Slider { Layout.fillWidth: true; thickness: Theme.px(10); value: Backlight.keys.value; onMoved: v => Backlight.keys.set(v) }
                    Label { Layout.preferredWidth: Theme.px(40); horizontalAlignment: Text.AlignRight; text: Math.round(Backlight.keys.value * 100) + "%"; color: Theme.islandTextDim }
                }
            }
        }
    }

    // dropdown bodies
    Component { id: wifiD; Detail { WifiView { Layout.fillWidth: true; listMax: Theme.px(170) } } }
    Component { id: btD; Detail { BluetoothView { Layout.fillWidth: true; listMax: Theme.px(170) } } }
    Component {
        id: micD
        Detail {
            AudioSection {
                kind: "source"; title: "Microphone"; iconOn: "mic"; iconOff: "mic_off"
                maxVol: Config.v.audio.maxInput; thickness: Theme.px(10)
            }
        }
    }
    Component {
        id: powerD
        Detail {
            Repeater {
                model: [
                    { name: "Power saver", icon: "eco", p: PowerProfile.PowerSaver, show: true },
                    { name: "Balanced", icon: "balance", p: PowerProfile.Balanced, show: true },
                    { name: "Performance", icon: "speed", p: PowerProfile.Performance, show: PowerProfiles.hasPerformanceProfile }
                ].filter(m => m.show)
                delegate: ListItem {
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
    Component {
        id: shotD
        Detail {
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.px(8)
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "crop"; text: "Region"; onClicked: { Capture.screenshot("region", Panels.screenName); root.done() } }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "desktop_windows"; text: "Screen"; onClicked: { Capture.screenshot("screen", Panels.screenName); root.done() } }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "draw"; text: "Annotate"; onClicked: { Capture.screenshot("annotate", Panels.screenName); root.done() } }
            }
        }
    }
    Component {
        id: recD
        Detail {
            RowLayout {
                visible: !Capture.recording
                Layout.fillWidth: true
                spacing: Theme.px(8)
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "desktop_windows"; text: "Record screen"; onClicked: { Capture.record("screen", Panels.screenName); root.done() } }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "crop"; text: "Record region"; onClicked: { Capture.record("region", Panels.screenName); root.done() } }
            }
            ActionButton {
                visible: Capture.recording
                Layout.fillWidth: true
                icon: "stop_circle"; text: "Stop recording  " + root.clock(Capture.elapsed); danger: true
                onClicked: { Capture.stop(); root.done() }
            }
        }
    }
    Component { id: clipD; Detail { ClipboardView { Layout.fillWidth: true; onPicked: root.done() } } }
    Component {
        id: palD
        Detail {
            PanelHeader { icon: "palette"; title: "Palette" }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Theme.px(210))
                clip: true
                spacing: 2
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                model: Theming.palettes
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool cur: modelData.name === Theming.current
                    width: ListView.view.width
                    height: Theme.px(34)
                    radius: Theme.px(10)
                    color: cur || ph.hovered ? Theme.surface : "transparent"
                    HoverHandler { id: ph }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theming.set(pr.modelData.name) }
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
                        spacing: Theme.px(10)
                        Row {
                            spacing: -Theme.px(5)
                            Repeater {
                                model: [pr.modelData.bg, pr.modelData.accent, pr.modelData.text]
                                Rectangle {
                                    required property string modelData
                                    width: Theme.px(18); height: width; radius: width / 2
                                    color: modelData
                                    border.width: 1
                                    border.color: Qt.alpha(Theme.text, 0.25)
                                }
                            }
                        }
                        Label { Layout.fillWidth: true; text: pr.modelData.name; elide: Text.ElideRight }
                        Icon { visible: pr.cur; name: "check"; size: Theme.px(14); color: Theme.accent }
                    }
                }
            }
        }
    }

    // ================= Media =================
    Component {
        id: mediaC
        ColumnLayout {
            id: media
            readonly property var p: Media.player
            spacing: Theme.px(12)
            function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
            Timer {
                running: media.p !== null && media.p.isPlaying
                repeat: true; interval: 1000
                onTriggered: media.p.positionChanged()
            }

            // switch between sources
            Flow {
                visible: Media.usable.length > 1
                Layout.fillWidth: true
                spacing: Theme.px(6)
                Repeater {
                    model: Media.usable
                    delegate: Rectangle {
                        id: src
                        required property var modelData
                        readonly property bool sel: media.p !== null && Media.key(modelData) === Media.key(media.p)
                        implicitHeight: Theme.px(28)
                        implicitWidth: sl.implicitWidth + Theme.px(30)
                        radius: height / 2
                        color: sel ? Theme.accent : sh.hovered ? Theme.surfaceHi : Theme.surface
                        Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }
                        HoverHandler { id: sh }
                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.px(6)
                            Rectangle { visible: src.modelData.isPlaying; width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: src.sel ? Theme.accentText : Theme.good }
                            Label { id: sl; text: src.modelData.identity; color: src.sel ? Theme.accentText : Theme.text; font.pixelSize: Theme.fontSize - 1 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Media.select(src.modelData) }
                    }
                }
            }

            Rectangle {
                visible: media.p === null
                Layout.fillWidth: true
                implicitHeight: Theme.px(200)
                radius: Theme.px(18)
                color: Theme.surface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.px(6)
                    Icon { Layout.alignment: Qt.AlignHCenter; name: "music_off"; size: Theme.px(40); color: Theme.textFaint }
                    Label { Layout.alignment: Qt.AlignHCenter; text: "No active media"; font.weight: Font.DemiBold }
                    Label { Layout.alignment: Qt.AlignHCenter; text: "Play something and it shows up here"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
                }
            }

            RowLayout {
                visible: media.p !== null
                Layout.fillWidth: true
                spacing: Theme.px(16)
                ClippingRectangle {
                    implicitWidth: Theme.px(110); implicitHeight: Theme.px(110)
                    radius: Theme.px(18)
                    color: Theme.surface
                    Image {
                        anchors.fill: parent
                        source: media.p ? media.p.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 220
                        sourceSize.height: 220
                        visible: status === Image.Ready
                    }
                    Icon { anchors.centerIn: parent; name: "music_note"; size: Theme.px(34); color: Theme.textFaint }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.px(2)
                    RowLayout {
                        Layout.fillWidth: true
                        Label { Layout.fillWidth: true; text: media.p ? media.p.trackTitle : ""; color: Theme.islandText; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize + 3; elide: Text.ElideRight }
                        IconButton { name: "close"; tone: Theme.islandTextDim; onClicked: Media.closeSource(media.p) }
                    }
                    Label { Layout.fillWidth: true; text: media.p ? media.p.trackArtist : ""; color: Theme.islandTextDim; elide: Text.ElideRight }
                    Label { Layout.fillWidth: true; text: media.p ? media.p.identity : ""; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 2; elide: Text.ElideRight }
                    Bars { Layout.topMargin: Theme.px(6); count: 8; running: media.p !== null && media.p.isPlaying; tone: Theme.islandText }
                }
            }
            ColumnLayout {
                visible: media.p !== null
                Layout.fillWidth: true
                spacing: Theme.px(2)
                Slider {
                    Layout.fillWidth: true
                    thickness: Theme.px(8)
                    value: media.p && media.p.length > 0 ? media.p.position / media.p.length : 0
                    onMoved: v => { if (media.p && media.p.canSeek) media.p.position = v * media.p.length }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: media.p ? media.fmt(media.p.position) : ""; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 2 }
                    Item { Layout.fillWidth: true }
                    Label { text: media.p ? media.fmt(media.p.length) : ""; color: Theme.islandTextDim; font.pixelSize: Theme.fontSize - 2 }
                }
            }
            RowLayout {
                visible: media.p !== null
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.px(20)
                IconButton { name: "skip_previous"; tone: Theme.islandText; onClicked: media.p.previous() }
                Rectangle {
                    implicitWidth: Theme.px(44); implicitHeight: implicitWidth; radius: width / 2
                    color: Theme.accent
                    Icon { anchors.centerIn: parent; name: media.p && media.p.isPlaying ? "pause" : "play_arrow"; size: Theme.px(24); color: Theme.accentText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: media.p.togglePlaying() }
                }
                IconButton { name: "skip_next"; tone: Theme.islandText; onClicked: media.p.next() }
            }
        }
    }

    // ================= About =================
    Component {
        id: aboutC
        ColumnLayout {
            spacing: Theme.px(10)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.px(80)
                radius: Theme.px(18)
                color: Theme.surface
                RowLayout {
                    anchors { fill: parent; margins: Theme.px(14) }
                    spacing: Theme.px(14)
                    Rectangle {
                        implicitWidth: Theme.px(52); implicitHeight: implicitWidth; radius: Theme.px(16)
                        color: Theme.accent
                        Icon { anchors.centerIn: parent; name: "terminal"; size: Theme.px(28); color: Theme.accentText }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: SysInfo.os || "Linux"; font.pixelSize: Theme.fontSize + 4; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: "Kernel " + SysInfo.kernel; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
                    }
                    Rectangle {
                        visible: SysInfo.desktop !== ""
                        implicitHeight: Theme.px(26); implicitWidth: dl.implicitWidth + Theme.px(20); radius: height / 2
                        color: "transparent"; border.width: 1; border.color: Theme.accent
                        Label { id: dl; anchors.centerIn: parent; text: SysInfo.desktop; color: Theme.accent; font.pixelSize: Theme.fontSize - 1 }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.px(10)
                Repeater {
                    model: [
                        { name: "CPU", v: SysStats.cpu, sub: SysStats.cores + " cores" },
                        { name: "Memory", v: SysStats.memory, sub: (SysStats.memTotalKb / 1048576).toFixed(1) + " GB" },
                        { name: "Disk", v: SysStats.disk, sub: (SysStats.diskTotalB / 1e9).toFixed(0) + " GB" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        implicitHeight: Theme.px(124)
                        radius: Theme.px(18)
                        color: Theme.surface
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.px(4)
                            Ring {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: Theme.px(70); Layout.preferredHeight: Theme.px(70)
                                thickness: Theme.px(8)
                                value: modelData.v
                                tone: Theme.vitalColor(modelData.v)
                                Label { anchors.centerIn: parent; text: Math.round(modelData.v) + "%"; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize - 1 }
                            }
                            Label { Layout.alignment: Qt.AlignHCenter; text: modelData.name; font.weight: Font.DemiBold }
                            Label { Layout.alignment: Qt.AlignHCenter; text: modelData.sub; color: Theme.textDim; font.pixelSize: Theme.fontSize - 2 }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Theme.px(10)
                rowSpacing: Theme.px(10)

                Rectangle {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    implicitHeight: Theme.px(52); radius: Theme.px(16); color: Theme.surface
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.px(14); rightMargin: Theme.px(14) }
                        spacing: Theme.px(10)
                        Icon { name: "memory"; color: Theme.accent }
                        Label { text: SysInfo.cpu || "CPU"; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    implicitHeight: Theme.px(64); radius: Theme.px(16); color: Theme.surface
                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.px(12) }
                        spacing: 0
                        Label { text: "Uptime"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 2 }
                        Label { text: SysInfo.fmtUptime(SysInfo.uptimeSec); font.pixelSize: Theme.fontSize + 3; font.weight: Font.DemiBold; color: Theme.accent }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    implicitHeight: Theme.px(64); radius: Theme.px(16); color: Theme.surface
                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.px(12) }
                        spacing: Theme.px(6)
                        Label { text: "Palette  " + (Config.v.palette || "custom"); color: Theme.textDim; font.pixelSize: Theme.fontSize - 2; elide: Text.ElideRight; Layout.fillWidth: true }
                        Row {
                            spacing: Theme.px(6)
                            Repeater {
                                model: [Theme.accent, Theme.good, Theme.warn, Theme.warm, Theme.bad, Theme.info]
                                Rectangle { required property color modelData; width: Theme.px(16); height: width; radius: width / 2; color: modelData }
                            }
                        }
                    }
                }
            }
        }
    }
}

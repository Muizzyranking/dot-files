import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services
import qs.modules.bar

WlSessionLockSurface {
    id: surf
    color: Theme.barBg
    readonly property var cfg: Config.v.lock
    readonly property string wp: cfg.wallpaper !== "" ? cfg.wallpaper.replace(/^~/, Quickshell.env("HOME")) : Wallpaper.current
    readonly property real dpr: surf.screen ? surf.screen.devicePixelRatio : 1
    readonly property real sw: surf.screen ? surf.screen.width : 1920
    readonly property color clockTone: Theme.resolve(cfg.clockColor)
    property bool showPw: false

    SystemClock { id: sc; precision: SystemClock.Minutes }
    Component.onCompleted: { SysInfo.refresh(); input.forceActiveFocus() }

    Item {
        anchors.fill: parent

        Image {
            anchors.fill: parent
            visible: surf.cfg.blur <= 0
            source: surf.wp !== "" ? "file://" + surf.wp : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: surf.sw * surf.dpr
        }
        Image {
            id: bgBlur
            anchors.fill: parent
            visible: false
            source: surf.cfg.blur > 0 && surf.wp !== "" ? "file://" + surf.wp : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: surf.sw * surf.dpr * 0.6
        }
        MultiEffect {
            anchors.fill: parent
            visible: surf.cfg.blur > 0
            source: bgBlur
            blurEnabled: true
            blur: surf.cfg.blur
            blurMax: 48
            autoPaddingEnabled: false
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, surf.cfg.dim) }

        // top corner
        RowLayout {
            anchors { top: parent.top; right: parent.right; margins: Theme.px(20) }
            spacing: Theme.px(10)
            Pill {
                spacing: Theme.px(14)
                Icon { name: Net.icon; color: Net.wifiEnabled && (Net.wifiConnected || Net.ethernet) ? Theme.text : Theme.textDim }
                Icon { name: Bt.icon; color: Bt.connected > 0 ? Theme.info : Bt.enabled ? Theme.text : Theme.textDim }
                Icon { name: Audio.icon; color: Audio.muted ? Theme.textDim : Theme.text }
            }
            BatteryIcon {}
        }

        // centre
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.03
            spacing: Theme.px(8)

            // clock: "stacked" (hours over minutes, minutes in the accent colour) or "inline"
            ColumnLayout {
                visible: surf.cfg.clockStyle === "stacked"
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(sc.date, surf.cfg.dateFormat).toUpperCase()
                    color: surf.clockTone
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.px(25)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 5
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.px(6)
                    text: Qt.formatDateTime(sc.date, surf.cfg.hourFormat)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.px(surf.cfg.clockSize)
                    font.weight: Font.Black
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.4)
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -Theme.px(surf.cfg.clockSize * 0.16)
                    text: Qt.formatDateTime(sc.date, surf.cfg.minuteFormat)
                    color: surf.clockTone
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.px(surf.cfg.clockSize)
                    font.weight: Font.Thin
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.4)
                }
            }
            ColumnLayout {
                visible: surf.cfg.clockStyle !== "stacked"
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(sc.date, surf.cfg.timeFormat)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.px(surf.cfg.clockSize * 0.9)
                    font.weight: Font.Light
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.4)
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(sc.date, surf.cfg.dateFormat)
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.px(20)
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.px(26)
                implicitWidth: who.implicitWidth + Theme.px(36)
                implicitHeight: Theme.px(72)
                radius: height / 2
                color: Qt.alpha(Theme.surface, 0.6)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)
                RowLayout {
                    id: who
                    anchors.centerIn: parent
                    spacing: Theme.px(14)
                    Avatar { size: Theme.px(52) }
                    ColumnLayout {
                        spacing: 0
                        Label { text: Config.v.profile.name || SysInfo.host; font.pixelSize: Theme.px(18); font.weight: Font.DemiBold }
                        Label { text: "Locked  ·  up " + SysInfo.fmtUptime(SysInfo.uptimeSec); color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
                    }
                }
            }

            // password
            Rectangle {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.px(6)
                implicitWidth: Theme.px(360)
                implicitHeight: Theme.px(50)
                radius: height / 2
                color: Qt.alpha(Theme.surface, 0.88)
                border.width: 1
                border.color: input.activeFocus ? Theme.accent : Qt.alpha(Theme.text, 0.12)
                transform: Translate { id: shake }
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 14; duration: 80 }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                }
                Connections { target: Lock; function onFailedChanged() { shakeAnim.restart() } }
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.px(18); rightMargin: Theme.px(8) }
                    spacing: Theme.px(10)
                    Icon { name: "lock"; color: Theme.textDim }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        echoMode: surf.showPw ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        enabled: !Lock.busy
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        clip: true
                        text: Lock.password
                        onTextEdited: Lock.password = text
                        onAccepted: Lock.submit()
                        Keys.onEscapePressed: Lock.password = ""
                        Text {
                            visible: input.text === ""
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: Lock.busy ? "Checking..." : "Password"
                            color: Theme.textFaint
                            font: input.font
                        }
                    }
                    IconButton {
                        name: surf.showPw ? "visibility_off" : "visibility"
                        tone: surf.showPw ? Theme.accent : Theme.textDim
                        onClicked: { surf.showPw = !surf.showPw; input.forceActiveFocus() }
                    }
                    IconButton { name: "arrow_forward"; onClicked: Lock.submit() }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Lock.error
                color: Theme.bad
                opacity: Lock.error !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // media
            Rectangle {
                id: mc
                visible: surf.cfg.showMedia && Media.active
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.px(10)
                implicitWidth: Theme.px(360)
                implicitHeight: Theme.px(70)
                radius: Theme.px(20)
                color: Qt.alpha(Theme.surface, 0.8)
                readonly property var p: Media.islandPlayer
                RowLayout {
                    anchors { fill: parent; margins: Theme.px(10) }
                    spacing: Theme.px(12)
                    ClippingRectangle {
                        implicitWidth: Theme.px(50); implicitHeight: Theme.px(50)
                        radius: Theme.px(12)
                        color: Theme.surfaceHi
                        Image {
                            anchors.fill: parent
                            source: mc.p ? mc.p.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 100
                            sourceSize.height: 100
                            visible: status === Image.Ready
                        }
                        Icon { anchors.centerIn: parent; name: "music_note"; color: Theme.textFaint }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { Layout.fillWidth: true; text: mc.p ? mc.p.trackTitle : ""; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Label { Layout.fillWidth: true; text: mc.p ? mc.p.trackArtist : ""; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
                    }
                    IconButton { name: "skip_previous"; onClicked: mc.p.previous() }
                    IconButton { name: mc.p && mc.p.isPlaying ? "pause" : "play_arrow"; onClicked: mc.p.togglePlaying() }
                    IconButton { name: "skip_next"; onClicked: mc.p.next() }
                }
            }
        }
    }
}

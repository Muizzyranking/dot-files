import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

// Digital clock on the desktop. Position, size, formats and colour are in
// config.json "widgets.clock". Only updates once a minute unless seconds are on.
Item {
    id: root
    anchors.fill: parent
    property string screenName: ""
    readonly property var cfg: Config.v.widgets.clock
    visible: cfg.enabled && (cfg.monitors !== "primary" || Monitors.isPrimary(screenName))
    readonly property bool atLeft: cfg.position.endsWith("left")
    readonly property bool atRight: cfg.position.endsWith("right")
    readonly property bool atTop: cfg.position.startsWith("top")
    readonly property bool atBottom: cfg.position.startsWith("bottom")
    readonly property real m: Theme.px(cfg.margin)
    readonly property int align: atLeft ? Qt.AlignLeft : atRight ? Qt.AlignRight : Qt.AlignHCenter
    readonly property color tone: Qt.alpha(Theme.resolve(cfg.color), cfg.opacity)

    SystemClock { id: sc; precision: root.cfg.seconds ? SystemClock.Seconds : SystemClock.Minutes }

    ColumnLayout {
        spacing: 0
        anchors.left: root.atLeft ? parent.left : undefined
        anchors.right: root.atRight ? parent.right : undefined
        anchors.horizontalCenter: (!root.atLeft && !root.atRight) ? parent.horizontalCenter : undefined
        anchors.top: root.atTop ? parent.top : undefined
        anchors.bottom: root.atBottom ? parent.bottom : undefined
        anchors.verticalCenter: (!root.atTop && !root.atBottom) ? parent.verticalCenter : undefined
        anchors.leftMargin: root.m
        anchors.rightMargin: root.m
        anchors.topMargin: root.m
        anchors.bottomMargin: root.m

        Text {
            Layout.alignment: root.align
            text: Qt.formatDateTime(sc.date, root.cfg.seconds && root.cfg.timeFormat.indexOf("s") < 0 ? root.cfg.timeFormat + ":ss" : root.cfg.timeFormat)
            color: root.tone
            font.family: Theme.fontFamily
            font.pixelSize: Theme.px(root.cfg.size)
            font.weight: Font.Light
            style: root.cfg.shadow ? Text.Raised : Text.Normal
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }
        Text {
            Layout.alignment: root.align
            visible: root.cfg.dateFormat !== ""
            text: Qt.formatDateTime(sc.date, root.cfg.dateFormat)
            color: root.tone
            font.family: Theme.fontFamily
            font.pixelSize: Theme.px(root.cfg.dateSize)
            font.weight: Font.Medium
            style: root.cfg.shadow ? Text.Raised : Text.Normal
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }
    }
}

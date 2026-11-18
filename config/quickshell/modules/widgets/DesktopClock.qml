import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.services

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

    SystemClock { id: sc; precision: root.cfg.seconds ? SystemClock.Seconds : SystemClock.Minutes }

    BigClock {
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
        stamp: Qt.formatDateTime(sc.date, root.cfg.seconds && root.cfg.timeFormat.indexOf("s") < 0 ? root.cfg.timeFormat + ":ss" : root.cfg.timeFormat)
        dateStamp: root.cfg.dateFormat !== "" ? Qt.formatDateTime(sc.date, root.cfg.dateFormat).toUpperCase() : ""
        size: Theme.px(root.cfg.size)
        dateSize: root.cfg.dateSize > 0 ? Theme.px(root.cfg.dateSize) : root.size * 0.15
        tone: Qt.alpha(Theme.resolve(root.cfg.color), root.cfg.opacity)
        hoursTone: Qt.alpha(Theme.resolve(root.cfg.hourColor), root.cfg.opacity)
        shadow: root.cfg.shadow
    }
}

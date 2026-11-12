import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

Scope {
    id: root
    readonly property bool want: Launcher.open
    property bool keep: false
    onWantChanged: { if (!want) { keep = true; kt.restart() } else keep = false }
    Timer { id: kt; interval: 300; onTriggered: root.keep = false }

    LazyLoader {
        active: root.want || root.keep
        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Launcher.screenName) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property var cfg: Config.v.launcher
            property int sel: 0

            readonly property var apps: {
                const q = search.text.trim().toLowerCase()
                const all = Array.from(DesktopEntries.applications.values).filter(e => !e.noDisplay)
                const cnt = Launcher.counts
                if (q === "")
                    return all.sort((a, b) => (cnt[b.id] || 0) - (cnt[a.id] || 0) || a.name.localeCompare(b.name))
                const score = e => {
                    const n = e.name.toLowerCase()
                    if (n === q) return 100
                    if (n.startsWith(q)) return 80
                    if (n.includes(" " + q)) return 70
                    if (n.includes(q)) return 50
                    const rest = ((e.genericName || "") + " " + (e.comment || "") + " " + (e.keywords || []).join(" ")).toLowerCase()
                    return rest.includes(q) ? 20 : 0
                }
                return all.map(e => ({ e: e, s: score(e) })).filter(x => x.s > 0)
                    .sort((a, b) => b.s - a.s || (cnt[b.e.id] || 0) - (cnt[a.e.id] || 0)).map(x => x.e)
            }
            function launch(i) {
                const e = apps[i]
                if (!e) return
                Launcher.record(e.id)
                e.execute()
                Launcher.hide()
            }
            function move(d) { sel = Math.max(0, Math.min(apps.length - 1, sel + d)) }
            Component.onCompleted: search.focusInput()

            Item {
                focus: true
                Keys.onEscapePressed: Launcher.hide()
                Shortcut { sequence: "Escape"; onActivated: Launcher.hide() }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.barBg, win.cfg.dim)
                opacity: root.want ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea { anchors.fill: parent; onClicked: Launcher.hide() }
            }

            Item {
                anchors.fill: parent
                opacity: root.want ? 1 : 0
                scale: root.want ? 1 : 0.97
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                SearchField {
                    id: search
                    width: Math.min(parent.width - 80, Theme.px(560))
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.08
                    implicitHeight: Theme.px(46)
                    radius: height / 2
                    placeholder: "Search apps"
                    onTextChanged: win.sel = 0
                    onUp: win.move(-win.cfg.columns)
                    onDown: win.move(win.cfg.columns)
                    onNext: win.move(1)
                    onPrev: win.move(-1)
                    onAccepted: win.launch(win.sel)
                }

                GridView {
                    id: gv
                    anchors {
                        top: search.bottom; topMargin: Theme.px(36)
                        bottom: parent.bottom; bottomMargin: Theme.px(40)
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Math.min(parent.width - 120, win.cfg.columns * Theme.px(win.cfg.cellWidth))
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / win.cfg.columns)
                    cellHeight: Theme.px(win.cfg.cellHeight)
                    model: win.apps
                    currentIndex: win.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                    Label {
                        visible: win.apps.length === 0
                        anchors.centerIn: parent
                        text: "No apps found"
                        color: Theme.textDim
                    }

                    delegate: Item {
                        id: d
                        required property var modelData
                        required property int index
                        width: gv.cellWidth; height: gv.cellHeight
                        Rectangle {
                            anchors { fill: parent; margins: Theme.px(6) }
                            radius: Theme.px(18)
                            color: d.index === win.sel ? Qt.alpha(Theme.surface, 0.9) : "transparent"
                            border.width: d.index === win.sel ? 1 : 0
                            border.color: Qt.alpha(Theme.accent, 0.5)
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.px(8)
                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitSize: Theme.px(win.cfg.iconSize)
                                source: Quickshell.iconPath(d.modelData.icon, true) || Quickshell.iconPath("application-x-executable")
                            }
                            Label {
                                width: gv.cellWidth - Theme.px(24)
                                horizontalAlignment: Text.AlignHCenter
                                text: d.modelData.name
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = d.index
                            onClicked: win.launch(d.index)
                        }
                    }
                }
            }
        }
    }
}

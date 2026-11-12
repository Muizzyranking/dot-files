import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.components
import qs.services

// Standalone clipboard window. Open with: qs ipc call clipboard toggle
Scope {
    id: root
    readonly property bool want: Popups.open === "clipboard"
    property bool keep: false
    onWantChanged: { if (!want) { keep = true; kt.restart() } else keep = false }
    Timer { id: kt; interval: 300; onTriggered: root.keep = false }

    LazyLoader {
        active: root.want || root.keep
        OverlayWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Popups.screenName) ?? Quickshell.screens[0]
            open: root.want
            cardWidth: Theme.px(580)
            cardHeight: Theme.px(480)
            onCloseRequested: Popups.close()

            property int sel: 0
            readonly property var shown: {
                const q = search.text.trim().toLowerCase()
                return q ? Clip.items.filter(i => i.text.toLowerCase().includes(q)) : Clip.items
            }
            function pick(i) {
                if (shown[i]) { Clip.copy(shown[i].id); Popups.close() }
            }
            Component.onCompleted: { Clip.refresh(); search.focusInput() }

            ColumnLayout {
                anchors { fill: parent; margins: Theme.px(16) }
                spacing: Theme.px(10)
                PanelHeader {
                    icon: "content_paste"
                    title: "Clipboard"
                    IconButton { visible: Clip.items.length > 0; name: "delete_sweep"; onClicked: Clip.wipe() }
                }
                SearchField {
                    id: search
                    Layout.fillWidth: true
                    placeholder: "Search clipboard history"
                    onTextChanged: win.sel = 0
                    onUp: win.sel = Math.max(0, win.sel - 1)
                    onDown: win.sel = Math.min(win.shown.length - 1, win.sel + 1)
                    onAccepted: win.pick(win.sel)
                }
                Label {
                    visible: win.shown.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.px(20)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: Clip.items.length === 0 ? "Nothing here yet. History needs cliphist and a wl-paste watcher (see config.md)." : "No matches"
                    color: Theme.textDim
                }
                ListView {
                    id: lv
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.shown
                    currentIndex: win.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        id: d
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: Theme.px(36)
                        radius: Theme.px(10)
                        color: index === win.sel ? Theme.surface : "transparent"
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = d.index
                            onClicked: win.pick(d.index)
                        }
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.px(12); rightMargin: Theme.px(6) }
                            spacing: Theme.px(10)
                            Icon { name: d.modelData.text.startsWith("[[ binary") ? "image" : "notes"; color: d.index === win.sel ? Theme.accent : Theme.textDim; size: Theme.px(16) }
                            Label {
                                Layout.fillWidth: true
                                text: d.modelData.text.startsWith("[[ binary") ? "Image" : d.modelData.text
                                elide: Text.ElideRight
                            }
                            IconButton { name: "close"; onClicked: Clip.remove(d.modelData.id) }
                        }
                    }
                }
                Label { text: "Enter copies  ·  Esc closes"; color: Theme.textFaint; font.pixelSize: Theme.fontSize - 2 }
            }
        }
    }
}

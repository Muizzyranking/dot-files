import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Wallpaper picker popup.
// Thumbnails are small and only the visible ones are loaded.
Scope {
    id: root
    readonly property bool want: Popups.open === "wallpaper"
    property bool keep: false
    onWantChanged: { if (!want) { keep = true; kt.restart() } else keep = false }
    Timer { id: kt; interval: 300; onTriggered: root.keep = false }

    LazyLoader {
        active: root.want || root.keep
        OverlayWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Popups.screenName) ?? Quickshell.screens[0]
            open: root.want
            cardWidth: Theme.px(880)
            cardHeight: Theme.px(580)
            onCloseRequested: Popups.close()
            Component.onCompleted: Wallpaper.refresh()

            ColumnLayout {
                anchors { fill: parent; margins: Theme.px(16) }
                spacing: Theme.px(10)
                PanelHeader {
                    icon: "wallpaper"
                    title: "Wallpaper"
                    Label { text: Wallpaper.list.length + " images"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
                    IconButton { name: "shuffle"; onClicked: Wallpaper.random() }
                    IconButton { name: "refresh"; onClicked: Wallpaper.refresh() }
                }
                Label {
                    visible: Wallpaper.list.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.px(40)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "No images found in " + Wallpaper.folder + "\nChange wallpaper.dir in config.json."
                    color: Theme.textDim
                }
                GridView {
                    id: gv
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Wallpaper.list.length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / 4)
                    cellHeight: Math.floor(cellWidth * 0.64)
                    model: Wallpaper.list
                    delegate: Item {
                        id: d
                        required property string modelData
                        readonly property bool sel: Wallpaper.current === modelData
                        width: gv.cellWidth; height: gv.cellHeight
                        ClippingRectangle {
                            anchors { fill: parent; margins: Theme.px(5) }
                            radius: Theme.px(12)
                            color: Theme.surface
                            border.width: d.sel ? 3 : 0
                            border.color: Theme.accent
                            Image {
                                anchors.fill: parent
                                source: "file://" + d.modelData
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 320
                            }
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: Theme.px(22)
                                color: Qt.rgba(0, 0, 0, 0.55)
                                visible: ma.containsMouse || d.sel
                                Label {
                                    anchors { fill: parent; leftMargin: Theme.px(8); rightMargin: Theme.px(8) }
                                    text: d.modelData.split("/").pop()
                                    color: "#ffffff"
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideMiddle
                                }
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpaper.set(d.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

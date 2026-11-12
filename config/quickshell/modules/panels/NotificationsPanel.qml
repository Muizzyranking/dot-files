import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

ColumnLayout {
    id: root
    property real panelWidth: Theme.px(Config.v.panels.width + 50)
    spacing: Theme.px(10)
    readonly property var items: Array.from(Notifs.model.values).reverse()

    PanelHeader {
        icon: Notifs.dnd ? "notifications_off" : "notifications"
        title: "Notifications"
        IconButton { visible: root.items.length > 0; name: "delete_sweep"; onClicked: Notifs.clearAll() }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.px(40)
        radius: Theme.px(12)
        color: Theme.surface
        RowLayout {
            anchors { fill: parent; leftMargin: Theme.px(12); rightMargin: Theme.px(12) }
            spacing: Theme.px(10)
            Icon { name: "do_not_disturb_on"; color: Notifs.dnd ? Theme.accent : Theme.textDim }
            Label { text: "Do not disturb"; Layout.fillWidth: true }
            Toggle { checked: Notifs.dnd; onToggled: Notifs.toggleDnd() }
        }
    }

    ColumnLayout {
        visible: root.items.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Theme.px(14)
        Layout.bottomMargin: Theme.px(14)
        spacing: Theme.px(6)
        Icon { Layout.alignment: Qt.AlignHCenter; name: "notifications_none"; size: Theme.px(34); color: Theme.textFaint }
        Label { Layout.alignment: Qt.AlignHCenter; text: "You're all caught up"; color: Theme.textDim }
    }

    ListView {
        visible: root.items.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.min(contentHeight, Theme.px(380)) : 0
        clip: true
        spacing: Theme.px(8)
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: root.items

        delegate: Rectangle {
            id: card
            required property var modelData
            readonly property string iconSrc: modelData.image !== "" ? modelData.image
                : modelData.appIcon === "" ? ""
                : modelData.appIcon.startsWith("/") ? modelData.appIcon
                : Quickshell.iconPath(modelData.appIcon, true)
            width: ListView.view.width
            height: col.implicitHeight + Theme.px(24)
            radius: Theme.px(14)
            color: Theme.surface

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.px(12) }
                spacing: Theme.px(6)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.px(8)
                    Item {
                        implicitWidth: Theme.px(18); implicitHeight: Theme.px(18)
                        IconImage { anchors.fill: parent; visible: card.iconSrc !== ""; source: card.iconSrc }
                        Icon { anchors.centerIn: parent; visible: card.iconSrc === ""; name: "notifications"; size: Theme.px(16); color: Theme.textDim }
                    }
                    Label { Layout.fillWidth: true; text: card.modelData.appName; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
                    Label { text: Notifs.ago(card.modelData.id, Notifs.now); color: Theme.textFaint; font.pixelSize: Theme.fontSize - 2 }
                    IconButton { name: "close"; onClicked: card.modelData.dismiss() }
                }
                Label {
                    visible: card.modelData.summary !== ""
                    Layout.fillWidth: true
                    text: card.modelData.summary
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }
                Label {
                    visible: card.modelData.body !== ""
                    Layout.fillWidth: true
                    text: card.modelData.body
                    color: Theme.textDim
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: Config.v.notifications.maxLines
                    elide: Text.ElideRight
                }
                RowLayout {
                    visible: card.modelData.actions.length > 0
                    Layout.fillWidth: true
                    spacing: Theme.px(6)
                    Repeater {
                        model: card.modelData.actions
                        delegate: Rectangle {
                            id: act
                            required property var modelData
                            implicitHeight: Theme.px(26)
                            implicitWidth: al.implicitWidth + Theme.px(20)
                            radius: Theme.px(9)
                            color: ah.hovered ? Theme.surfaceHi : Theme.panel
                            HoverHandler { id: ah }
                            Label { id: al; anchors.centerIn: parent; text: act.modelData.text; color: Theme.accent; font.pixelSize: Theme.fontSize - 1 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: act.modelData.invoke() }
                        }
                    }
                }
            }
        }
    }
}

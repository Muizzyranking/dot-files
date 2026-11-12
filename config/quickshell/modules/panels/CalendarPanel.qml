import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components

ColumnLayout {
    id: root
    readonly property real cell: Theme.px(40)
    property real panelWidth: cell * 7
    spacing: Theme.px(8)

    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    readonly property int firstDay: Config.v.calendar.firstDay
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function shift(d) {
        const m = month + d
        year += Math.floor(m / 12)
        month = ((m % 12) + 12) % 12
    }
    function goToday() { const t = new Date(); year = t.getFullYear(); month = t.getMonth() }

    readonly property var cells: {
        const first = new Date(year, month, 1)
        const offset = (first.getDay() - firstDay + 7) % 7
        const dim = new Date(year, month + 1, 0).getDate()
        const prevDim = new Date(year, month, 0).getDate()
        const t = new Date()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = i - offset + 1
            const inMonth = d >= 1 && d <= dim
            out.push({
                d: inMonth ? d : d < 1 ? prevDim + d : d - dim,
                inMonth,
                today: inMonth && d === t.getDate() && month === t.getMonth() && year === t.getFullYear()
            })
        }
        return out
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(6)
        Label {
            Layout.fillWidth: true
            text: root.monthNames[root.month] + " " + root.year
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fontSize + 2
        }
        IconButton { name: "today"; onClicked: root.goToday() }
        IconButton { name: "chevron_left"; onClicked: root.shift(-1) }
        IconButton { name: "chevron_right"; onClicked: root.shift(1) }
    }

    Row {
        Repeater {
            model: 7
            delegate: Label {
                required property int index
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: root.dayNames[(index + root.firstDay) % 7]
                color: Theme.textFaint
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    Grid {
        columns: 7
        Repeater {
            model: root.cells
            delegate: Item {
                id: c
                required property var modelData
                width: root.cell; height: Theme.px(34)
                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.px(30); height: width; radius: width / 2
                    color: c.modelData.today ? Theme.accent : ch.hovered ? Theme.surface : "transparent"
                    HoverHandler { id: ch }
                }
                Label {
                    anchors.centerIn: parent
                    text: c.modelData.d
                    color: c.modelData.today ? Theme.accentText : c.modelData.inMonth ? Theme.text : Theme.textFaint
                    font.weight: c.modelData.today ? Font.DemiBold : Font.Medium
                }
            }
        }
    }
}

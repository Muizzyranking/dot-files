import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services

RowLayout {
    id: r
    required property var row
    readonly property var spec: row.spec
    readonly property real val: Settings.get(row.path) ?? spec.min
    spacing: Theme.px(10)
    Slider {
        Layout.preferredWidth: Theme.px(200)
        thickness: Theme.px(6)
        value: (r.val - r.spec.min) / (r.spec.max - r.spec.min)
        onMoved: v => {
            const raw = r.spec.min + v * (r.spec.max - r.spec.min)
            const q = Math.round(raw / r.spec.step) * r.spec.step
            Settings.setPath(r.row.path, Math.round(q * 1000) / 1000)
        }
    }
    Label {
        Layout.preferredWidth: Theme.px(50)
        horizontalAlignment: Text.AlignRight
        text: r.spec.step < 1 ? r.val.toFixed(2) : String(r.val)
        color: Theme.textDim
    }
}

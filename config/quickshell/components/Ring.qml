import QtQuick
import qs.core

// Circular gauge. value is 0..100.
Canvas {
    id: root
    property real value: 0
    property color tone: Theme.accent
    property real thickness: Theme.px(14)
    property real shown: value
    Behavior on shown { NumberAnimation { duration: Config.v.animation.slow; easing.type: Easing.OutCubic } }
    onShownChanged: requestPaint()
    onToneChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2, cy = height / 2
        const r = Math.min(width, height) / 2 - thickness / 2 - 2
        ctx.lineWidth = thickness
        ctx.lineCap = "round"
        ctx.strokeStyle = String(Theme.surfaceHi)
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
        const a = Math.max(0.5, Math.min(100, shown))
        ctx.strokeStyle = String(tone)
        ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * a / 100); ctx.stroke()
    }
}

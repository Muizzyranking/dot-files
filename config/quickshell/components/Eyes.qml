import QtQuick
import qs.core
import qs.services

// Robot eyes. The mood (services/Mood.qml) changes their shape and colour with a smooth
// morph, and the eyes blink whenever it changes. Random drift and blinking.
// Drawn on one small canvas; nothing runs while the eyes are hidden.
Item {
    id: root
    property bool active: true
    property string mood: Mood.current

    readonly property real eyeW: Theme.px(Config.v.eyes.width)
    readonly property real eyeH: Theme.px(Config.v.eyes.height)
    readonly property real gap: Theme.px(Config.v.eyes.gap)
    readonly property real cellW: eyeW * 1.5
    readonly property color target: Theme.resolve(Config.v.eyes.moodColors[mood] ?? Config.v.eyes.color)
    readonly property color bg: Theme.resolve(Config.v.island.color)
    property color tone: target
    Behavior on tone { ColorAnimation { duration: 320 } }

    property real blinkAmt: 0
    property real driftX: 0
    property real driftY: 0
    property real t: 1
    property var from: null
    property var to: null

    implicitWidth: cellW * 2 + gap
    implicitHeight: eyeH * 1.7

    // outer/inner: "o" is the edge away from the nose, "i" the edge toward it.
    // t* = top lid height at outer/inner/centre, b* = bottom lid, as a fraction of the eye.
    function shape(o) { return Object.assign({ to: 0, ti: 0, tc: 0, bo: 1, bi: 1, bc: 1, w: 1, h: 1, r: 0.45, pupil: 0 }, o) }
    readonly property var shapes: {
        const happy = shape({ to: 0.38, ti: 0.38, tc: 0, bc: 0.55, h: 1.15 })
        return {
            neutral: { l: shape({}), r: shape({}) },
            happy: { l: happy, r: happy },
            playful: { l: shape({ h: 1.05 }), r: shape({ to: 0.38, ti: 0.38, tc: 0, bc: 0.55, w: 1.1 }) },
            sleepy: { l: shape({ to: 0.35, ti: 0.35, tc: 0.8, h: 0.9 }), r: shape({ to: 0.35, ti: 0.35, tc: 0.8, h: 0.9 }) },
            moody: { l: shape({ to: 0.45, ti: 0.45, tc: 0.45 }), r: shape({ to: 0.45, ti: 0.45, tc: 0.45 }) },
            tired: { l: shape({ to: 0.62, ti: 0.3, tc: 0.47, h: 0.95 }), r: shape({ to: 0.62, ti: 0.3, tc: 0.47, h: 0.95 }) },
            sad: { l: shape({ to: 0.5, ti: 0, tc: 0.25, h: 0.95 }), r: shape({ to: 0.5, ti: 0, tc: 0.25, h: 0.95 }) },
            angry: { l: shape({ to: 0, ti: 0.55, tc: 0.27, w: 1.05 }), r: shape({ to: 0, ti: 0.55, tc: 0.27, w: 1.05 }) },
            scared: { l: shape({ w: 1.3, h: 1.4, r: 0.5, pupil: 0.38 }), r: shape({ w: 1.3, h: 1.4, r: 0.5, pupil: 0.38 }) }
        }
    }
    function lerp(a, b, k) {
        const o = {}
        for (const key in a) o[key] = a[key] + (b[key] - a[key]) * k
        return o
    }
    function at(side) { return lerp(from[side], to[side], t) }

    function morphTo(name) {
        const next = shapes[name] ?? shapes.neutral
        from = { l: at("l"), r: at("r") }
        to = next
        t = 0
        morph.restart()
        blink()
    }
    onMoodChanged: if (from !== null) morphTo(mood)
    Component.onCompleted: { to = shapes[mood] ?? shapes.neutral; from = to; t = 1 }
    NumberAnimation { id: morph; target: root; property: "t"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }

    function blink() { if (!blinkAnim.running) blinkAnim.start() }
    function rand(a, b) { return a + Math.random() * (b - a) }
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "blinkAmt"; to: 1; duration: 70; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "blinkAmt"; to: 0; duration: 120; easing.type: Easing.OutQuad }
    }
    Timer {
        running: root.active
        interval: root.rand(Config.v.eyes.blinkMinMs, Config.v.eyes.blinkMaxMs)
        onTriggered: {
            root.blink()
            interval = Math.random() < 0.2 ? 260 : root.rand(Config.v.eyes.blinkMinMs, Config.v.eyes.blinkMaxMs)
            restart()
        }
    }
    Timer {
        running: root.active && Config.v.eyes.driftEnabled
        interval: root.rand(1500, 4000)
        onTriggered: {
            const d = Theme.px(Config.v.eyes.drift)
            const home = Math.random() < 0.4
            root.driftX = home ? 0 : root.rand(-d, d)
            root.driftY = home ? 0 : root.rand(-d * 0.6, d * 0.6)
            interval = root.rand(1500, 4000)
            restart()
        }
    }
    Behavior on driftX { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
    Behavior on driftY { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            if (root.from === null) return
            const ctx = getContext("2d")
            ctx.reset()
            for (let i = 0; i < 2; i++) {
                const p = root.at(i === 0 ? "l" : "r")
                const flip = i === 1
                const ew = root.eyeW * p.w
                const eh = Math.max(2, root.eyeH * p.h * (1 - root.blinkAmt * 0.92))
                const cx = (i === 0 ? root.cellW / 2 : root.cellW + root.gap + root.cellW / 2) + root.driftX
                const cy = height / 2 + root.driftY
                const x0 = cx - ew / 2, y0 = cy - eh / 2
                const tl = flip ? p.ti : p.to, tr = flip ? p.to : p.ti
                const bl = flip ? p.bi : p.bo, br = flip ? p.bo : p.bi
                const ctop = y0 + (2 * p.tc - (tl + tr) / 2) * eh
                const cbot = y0 + (2 * p.bc - (bl + br) / 2) * eh
                ctx.save()
                ctx.beginPath()
                ctx.moveTo(x0 - 1, y0 + tl * eh)
                ctx.quadraticCurveTo(cx, ctop, x0 + ew + 1, y0 + tr * eh)
                ctx.lineTo(x0 + ew + 1, y0 + br * eh)
                ctx.quadraticCurveTo(cx, cbot, x0 - 1, y0 + bl * eh)
                ctx.closePath()
                ctx.clip()
                const rad = Math.min(ew, eh) * p.r
                ctx.beginPath()
                ctx.roundedRect(x0, y0, ew, eh, rad, rad)
                ctx.fillStyle = String(root.tone)
                ctx.fill()
                if (p.pupil > 0.01) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, Math.min(ew, eh) * p.pupil, 0, Math.PI * 2)
                    ctx.fillStyle = String(root.bg)
                    ctx.fill()
                }
                ctx.restore()
            }
        }
    }
    onBlinkAmtChanged: cv.requestPaint()
    onDriftXChanged: cv.requestPaint()
    onDriftYChanged: cv.requestPaint()
    onTChanged: cv.requestPaint()
    onToneChanged: cv.requestPaint()
}

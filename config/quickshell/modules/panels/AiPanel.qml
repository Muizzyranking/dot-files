import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services
import qs.modules.settings

// Sessions, pending prompts and the suspend-inhibit switch for every
// registered AI provider (see services/Ai.qml).
ColumnLayout {
    id: root
    property real panelWidth: Theme.px(Config.v.panels.width)
    spacing: Theme.px(10)
    Component.onCompleted: AiOpencode.refresh()

    function setInhibit(v) { Settings.setPath(["ai", "suspendInhibit"], v) }
    function fmtTokens(n) {
        if (!n) return "0"
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M"
        if (n >= 1000) return (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "k"
        return String(n)
    }
    function fmtAgo(ms) {
        const s = Math.max(0, (Date.now() - ms) / 1000)
        if (s < 60) return "now"
        const m = Math.floor(s / 60)
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        if (h < 24) return h + "h " + (m % 60) + "m"
        return Math.floor(h / 24) + "d"
    }
    function statusTone(id) {
        const t = AiOpencode.status(id)
        return t === "busy" ? Theme.accent : t === "retry" ? Theme.warn : Theme.textFaint
    }

    PanelHeader {
        icon: "smart_toy"
        title: "AI agents"
        RowLayout {
            spacing: Theme.px(8)
            Label { text: "Inhibit"; color: Theme.textDim; font.pixelSize: Theme.fontSize - 1 }
            Toggle {
                checked: Ai.inhibitArmed
                onToggled: root.setInhibit(!Ai.inhibitArmed)
            }
        }
    }

    Label {
        Layout.fillWidth: true
        color: Theme.textDim
        text: {
            if (!Ai.running) return "opencode is not running"
            const busy = AiOpencode.sessions.filter(s => {
                const t = AiOpencode.status(s.id)
                return t === "busy" || t === "retry"
            }).length
            const wait = Ai.attention
            const parts = []
            if (busy > 0) parts.push(busy + " working")
            if (wait > 0) parts.push(wait + " waiting for you")
            return parts.length > 0 ? parts.join(" · ") : "All agents idle"
        }
    }

    // ---- pending prompts (permission + question requests) ----
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.px(6)
        visible: Ai.attention > 0

        Repeater {
            model: AiOpencode.requests

            delegate: Rectangle {
                id: req
                required property var modelData
                readonly property var title: modelData.kind === "question"
                    ? (modelData.questions[0]?.header ?? "Question")
                    : modelData.name
                Layout.fillWidth: true
                implicitHeight: reqCol.implicitHeight + Theme.px(16)
                radius: Theme.px(10)
                color: Theme.surface
                border.width: 1
                border.color: Qt.alpha(Theme.warn, 0.5)

                ColumnLayout {
                    id: reqCol
                    x: Theme.px(10); y: Theme.px(8)
                    width: parent.width - Theme.px(20)
                    spacing: Theme.px(6)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.px(6)
                        Icon { name: req.modelData.kind === "question" ? "help" : "key"; size: Theme.px(14); color: Theme.warn }
                        Label { text: req.title; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    // permission: allow once, always, or deny
                    RowLayout {
                        visible: req.modelData.kind === "permission"
                        spacing: Theme.px(6)
                        ActionButton { Layout.fillWidth: true; implicitHeight: Theme.px(34); icon: "check"; text: "Allow"; onClicked: AiOpencode.permissionReply(req.modelData.sessionID, req.modelData.id, "once") }
                        ActionButton { Layout.fillWidth: true; implicitHeight: Theme.px(34); icon: "done_all"; text: "Always"; onClicked: AiOpencode.permissionReply(req.modelData.sessionID, req.modelData.id, "always") }
                        ActionButton { Layout.fillWidth: true; implicitHeight: Theme.px(34); icon: "close"; text: "Deny"; danger: true; onClicked: AiOpencode.permissionReply(req.modelData.sessionID, req.modelData.id, "reject") }
                    }

                    // question: one button per option, plus reject
                    RowLayout {
                        visible: req.modelData.kind === "question"
                        spacing: Theme.px(6)
                        Repeater {
                            model: (req.modelData.questions[0]?.options ?? []).slice(0, 3)
                            delegate: ActionButton {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Theme.px(34)
                                icon: ""
                                text: modelData.label
                                onClicked: AiOpencode.questionReply(req.modelData.sessionID, req.modelData.id,
                                    req.modelData.questions.map(q => [modelData.label]))
                            }
                        }
                        ActionButton {
                            Layout.fillWidth: true
                            implicitHeight: Theme.px(34)
                            icon: "close"
                            text: "Reject"
                            danger: true
                            onClicked: AiOpencode.questionReject(req.modelData.sessionID, req.modelData.id)
                        }
                    }
                }
            }
        }
    }

    // ---- sessions ----
    Label {
        visible: Ai.running
        text: "Sessions"
        color: Theme.textDim
        font.pixelSize: Theme.fontSize - 1
    }
    ListView {
        id: list
        visible: Ai.running && AiOpencode.sessions.length > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Theme.px(400))
        clip: true
        spacing: Theme.px(4)
        model: AiOpencode.sessions
        cacheBuffer: 0
        reuseItems: true

        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool isBusy: AiOpencode.status(row.modelData.id) === "busy" || AiOpencode.status(row.modelData.id) === "retry"
            readonly property int pct: AiOpencode.contextPct(row.modelData)
            readonly property real used: (row.modelData.tokens?.input ?? 0) + (row.modelData.tokens?.cache?.read ?? 0)
            readonly property string tokens: root.fmtTokens(row.used) + (row.pct >= 0 ? " (" + row.pct + "%)" : "")
            width: list.width
            implicitHeight: Theme.px(46)
            radius: Theme.px(10)
            color: rArea.containsMouse ? Theme.surfaceHi : Theme.surface

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
                spacing: Theme.px(8)

                Rectangle {
                    implicitWidth: Theme.px(7); implicitHeight: Theme.px(7)
                    radius: width / 2
                    color: root.statusTone(row.modelData.id)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: row.modelData.title ?? row.modelData.id; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label {
                        text: (row.modelData.agent ?? "agent") + " · " + (row.modelData.model?.id ?? "")
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSize - 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Label {
                        text: row.tokens
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Label {
                        text: row.isBusy ? "busy" : fmtAgo(row.modelData.time?.updated ?? 0) + " ago"
                        color: row.isBusy ? Theme.accent : Theme.textFaint
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
                IconButton {
                    visible: row.isBusy
                    name: "stop"
                    tone: Theme.bad
                    onClicked: AiOpencode.interrupt(row.modelData.id)
                }
            }
            MouseArea {
                id: rArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AiOpencode.reveal()
            }
        }
    }

    Label {
        visible: Ai.running && AiOpencode.sessions.length === 0
        text: "No sessions yet"
        color: Theme.textDim
    }

    // ---- totals ----
    Label {
        visible: Ai.running && AiOpencode.sessions.length > 0
        color: Theme.textDim
        font.pixelSize: Theme.fontSize - 1
        text: {
            let cost = 0, tok = 0
            for (const s of AiOpencode.sessions) {
                cost += s.cost ?? 0
                tok += (s.tokens?.input ?? 0) + (s.tokens?.output ?? 0)
            }
            return "Total " + fmtTokens(tok) + " tokens" + (cost > 0 ? " · $" + cost.toFixed(2) : "")
        }
    }
}

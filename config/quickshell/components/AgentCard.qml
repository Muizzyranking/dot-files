import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components

// Reusable Agent Card component. Can be used for any AI provider (Antigravity,
// OpenCode, Claude, Codex, Freebuff) with declarative capability flags.
Rectangle {
    id: root

    property var provider: null
    property bool supportsResumption: true
    property bool supportsDeletion: true
    property bool supportsRequests: true
    property bool supportsSessions: true
    property bool supportsTelemetry: true

    readonly property bool isBusy: provider ? provider.busy : false
    readonly property bool hasAttention: provider ? (provider.attention > 0) : false
    readonly property bool isReady: provider ? provider.ready : false

    // Collapsed by default unless working or action is required
    property bool userToggled: false
    property bool userOpen: false
    readonly property bool open: userToggled ? userOpen : (isBusy || hasAttention)

    Layout.fillWidth: true
    implicitHeight: cardBody.implicitHeight + Theme.px(18)
    radius: Theme.px(12)
    color: Theme.surface
    clip: true
    border.width: 1
    border.color: isBusy ? Qt.alpha(Theme.accent, 0.7)
        : hasAttention ? Qt.alpha(Theme.warn, 0.7)
        : Qt.alpha(Theme.text, 0.08)

    Behavior on implicitHeight {
        NumberAnimation { duration: Config.v.animation.fast; easing.type: Easing.OutCubic }
    }

    function fmtTokens(n) {
        if (!n) return "0"
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M"
        if (n >= 1000) return (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "k"
        return String(n)
    }

    function fmtAgo(ms) {
        if (!ms) return "now"
        const s = Math.max(0, (Date.now() - ms) / 1000)
        if (s < 60) return "now"
        const m = Math.floor(s / 60)
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        if (h < 24) return h + "h " + (m % 60) + "m"
        return Math.floor(h / 24) + "d"
    }

    ColumnLayout {
        id: cardBody
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.px(9)
        }
        spacing: Theme.px(7)

        // ================= HEADER (Always Visible & Clickable) =================
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.px(8)

            // Status Indicator Dot
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Theme.px(8)
                implicitHeight: Theme.px(8)
                radius: width / 2
                color: root.isBusy ? Theme.accent
                    : root.hasAttention ? Theme.warn
                    : root.isReady ? Theme.good : Theme.textDim

                SequentialAnimation on scale {
                    running: root.isBusy
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.4; duration: 750; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
                }
            }

            // Agent Icon
            Icon {
                Layout.alignment: Qt.AlignVCenter
                name: (root.provider && root.provider.icon) ? root.provider.icon : "smart_toy"
                size: Theme.px(16)
                color: root.isBusy ? Theme.accent : Theme.text
            }

            // Agent Name
            Label {
                Layout.alignment: Qt.AlignVCenter
                text: (root.provider && root.provider.name) ? root.provider.name : "Agent"
                font.weight: Font.DemiBold
                font.pixelSize: Theme.fontSize
            }

            // Model Badge
            Rectangle {
                visible: root.provider && root.provider.model && root.provider.model !== ""
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Theme.px(20)
                implicitWidth: Math.min(Theme.px(100), mdlTxt.implicitWidth + Theme.px(10))
                radius: Theme.px(6)
                color: Theme.surfaceHi
                clip: true

                Label {
                    id: mdlTxt
                    anchors.centerIn: parent
                    width: parent.width - Theme.px(8)
                    text: root.provider ? root.provider.model : ""
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.textDim
                }
            }

            Item { Layout.fillWidth: true }

            // Live Timer / Status Badge
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Theme.px(22)
                implicitWidth: statusTxt.implicitWidth + Theme.px(12)
                radius: Theme.px(11)
                color: root.isBusy ? Qt.alpha(Theme.accent, 0.22)
                    : root.hasAttention ? Qt.alpha(Theme.warn, 0.22)
                    : Theme.surfaceHi

                Label {
                    id: statusTxt
                    anchors.centerIn: parent
                    text: {
                        if (!root.provider) return "Off"
                        if (root.isBusy) {
                            const dur = root.provider.fmtDuration
                                ? root.provider.fmtDuration(root.provider.liveElapsedMs)
                                : Math.round(root.provider.liveElapsedMs / 1000) + "s"
                            return "⏱ " + dur
                        }
                        if (root.hasAttention) return "Input needed"
                        if (root.provider.elapsedMs > 0) {
                            const dur = root.provider.fmtDuration
                                ? root.provider.fmtDuration(root.provider.elapsedMs)
                                : Math.round(root.provider.elapsedMs / 1000) + "s"
                            return "Took " + dur
                        }
                        return root.isReady ? "Idle" : "Off"
                    }
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.DemiBold
                    color: root.isBusy ? Theme.accent
                        : root.hasAttention ? Theme.warn
                        : Theme.textDim
                }
            }

            // Expand/Collapse Arrow
            Icon {
                Layout.alignment: Qt.AlignVCenter
                name: root.open ? "expand_less" : "expand_more"
                size: Theme.px(16)
                color: Theme.textDim
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.userOpen = !root.open
                    root.userToggled = true
                }
            }
        }

        // ================= EXPANDED CONTENT =================
        ColumnLayout {
            visible: root.open
            Layout.fillWidth: true
            spacing: Theme.px(6)

            // Token Telemetry
            Label {
                visible: root.supportsTelemetry && root.provider
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - 2
                color: Theme.textDim
                text: {
                    if (!root.provider) return ""
                    return "In " + root.fmtTokens(root.provider.inputTokens) +
                           " · Out " + root.fmtTokens(root.provider.outputTokens) +
                           " · Cache " + root.fmtTokens(root.provider.cacheReadTokens)
                }
            }

            // Prompt snippet box (strictly elided to prevent horizontal overflow)
            Rectangle {
                visible: root.supportsTelemetry && root.provider && root.provider.lastPrompt && root.provider.lastPrompt !== ""
                Layout.fillWidth: true
                implicitHeight: promptRow.implicitHeight + Theme.px(10)
                radius: Theme.px(8)
                color: Qt.alpha(Theme.barBg, 0.6)
                clip: true

                RowLayout {
                    id: promptRow
                    anchors {
                        fill: parent
                        leftMargin: Theme.px(8)
                        rightMargin: Theme.px(8)
                    }
                    spacing: Theme.px(6)

                    Icon {
                        Layout.alignment: Qt.AlignVCenter
                        name: "chat_bubble_outline"
                        size: Theme.px(13)
                        color: Theme.textFaint
                    }

                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        text: root.provider ? root.provider.lastPrompt : ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.textDim
                    }
                }
            }

            // Attention Requests (Permissions & Questions)
            ColumnLayout {
                visible: root.supportsRequests && root.provider && root.provider.requests && root.provider.requests.length > 0
                Layout.fillWidth: true
                spacing: Theme.px(6)

                Repeater {
                    model: (root.provider && root.provider.requests) ? root.provider.requests : []

                    delegate: Rectangle {
                        id: req
                        required property var modelData
                        readonly property var title: modelData.kind === "question"
                            ? (modelData.questions && modelData.questions[0] && modelData.questions[0].header ? modelData.questions[0].header : "Question")
                            : modelData.name
                        Layout.fillWidth: true
                        implicitHeight: reqCol.implicitHeight + Theme.px(14)
                        radius: Theme.px(8)
                        color: Theme.surfaceHi
                        border.width: 1
                        border.color: Qt.alpha(Theme.warn, 0.5)

                        ColumnLayout {
                            id: reqCol
                            x: Theme.px(8); y: Theme.px(6)
                            width: parent.width - Theme.px(16)
                            spacing: Theme.px(6)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.px(6)
                                Icon { Layout.alignment: Qt.AlignVCenter; name: req.modelData.kind === "question" ? "help" : "key"; size: Theme.px(14); color: Theme.warn }
                                Label { Layout.alignment: Qt.AlignVCenter; text: req.title; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            }

                            RowLayout {
                                visible: req.modelData.kind === "permission"
                                spacing: Theme.px(6)
                                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: Theme.px(30); iconSize: Theme.px(12); icon: "check"; text: "Allow"; onClicked: root.provider.permissionReply(req.modelData.sessionID, req.modelData.id, "once") }
                                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: Theme.px(30); iconSize: Theme.px(12); icon: "done_all"; text: "Always"; onClicked: root.provider.permissionReply(req.modelData.sessionID, req.modelData.id, "always") }
                                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: Theme.px(30); iconSize: Theme.px(12); icon: "close"; text: "Deny"; danger: true; onClicked: root.provider.permissionReply(req.modelData.sessionID, req.modelData.id, "reject") }
                            }

                            RowLayout {
                                visible: req.modelData.kind === "question"
                                spacing: Theme.px(6)
                                Repeater {
                                    model: (req.modelData.questions && req.modelData.questions[0] && req.modelData.questions[0].options ? req.modelData.questions[0].options : []).slice(0, 3)
                                    delegate: ActionButton {
                                        required property var modelData
                                        Layout.fillWidth: true; Layout.preferredWidth: 1
                                        implicitHeight: Theme.px(30); iconSize: Theme.px(12)
                                        text: modelData.label
                                        onClicked: root.provider.questionReply(req.modelData.sessionID, req.modelData.id, req.modelData.questions.map(q => [modelData.label]))
                                    }
                                }
                                ActionButton {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: Theme.px(30); iconSize: Theme.px(12); icon: "close"; text: "Reject"; danger: true
                                    onClicked: root.provider.questionReject(req.modelData.sessionID, req.modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // Sessions List (Active & Recent Sessions with Copy/Resume & Delete)
            ColumnLayout {
                visible: root.supportsSessions && root.provider && root.provider.sessions && root.provider.sessions.length > 0
                Layout.fillWidth: true
                spacing: Theme.px(4)

                Label {
                    text: "Sessions"
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.textDim
                }

                Repeater {
                    model: (root.provider && root.provider.sessions) ? root.provider.sessions.slice(0, 5) : []

                    delegate: Rectangle {
                        id: sessRow
                        required property var modelData
                        readonly property bool isSessionBusy: root.provider.status
                            ? (root.provider.status(sessRow.modelData.id) === "busy" || root.provider.status(sessRow.modelData.id) === "retry")
                            : (sessRow.modelData.isActive && root.isBusy)
                        property bool copied: false
                        property bool armedDelete: false

                        Layout.fillWidth: true
                        implicitHeight: Theme.px(38)
                        radius: Theme.px(8)
                        color: Theme.surfaceHi
                        clip: true

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Theme.px(8)
                                rightMargin: Theme.px(8)
                            }
                            spacing: Theme.px(6)

                            // Status Dot
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: Theme.px(6)
                                implicitHeight: Theme.px(6)
                                radius: 3
                                color: sessRow.isSessionBusy ? Theme.accent : Theme.textDim
                            }

                            // Session Title / ID
                            Label {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: sessRow.modelData.title || (sessRow.modelData.id || "").substring(0, 16)
                                elide: Text.ElideRight
                                font.pixelSize: Theme.fontSize - 2
                            }

                            // Time ago
                            Label {
                                Layout.alignment: Qt.AlignVCenter
                                text: root.fmtAgo(sessRow.modelData.updated || (sessRow.modelData.time && sessRow.modelData.time.updated ? sessRow.modelData.time.updated : 0))
                                color: Theme.textFaint
                                font.pixelSize: Theme.fontSize - 2
                            }

                            // Stop button (if busy)
                            IconButton {
                                visible: sessRow.isSessionBusy && root.provider.interrupt !== undefined
                                Layout.alignment: Qt.AlignVCenter
                                name: "stop"
                                tone: Theme.bad
                                onClicked: root.provider.interrupt(sessRow.modelData.id)
                            }

                            // Copy Resume Command Button (restored)
                            IconButton {
                                visible: root.supportsResumption && root.provider && root.provider.copyCommand !== undefined
                                Layout.alignment: Qt.AlignVCenter
                                name: sessRow.copied ? "check" : "content_copy"
                                tone: sessRow.copied ? Theme.good : Theme.textDim
                                onClicked: {
                                    root.provider.copyCommand(sessRow.modelData.id)
                                    sessRow.copied = true
                                    copyTimer.restart()
                                }
                                Timer {
                                    id: copyTimer
                                    interval: 2000
                                    onTriggered: sessRow.copied = false
                                }
                            }

                            // Delete Session Button (restored with confirmation)
                            IconButton {
                                visible: root.supportsDeletion && root.provider && root.provider.removeSession !== undefined
                                Layout.alignment: Qt.AlignVCenter
                                name: sessRow.armedDelete ? "delete_forever" : "delete"
                                tone: sessRow.armedDelete ? Theme.bad : Theme.textFaint
                                onClicked: {
                                    if (!sessRow.armedDelete) {
                                        sessRow.armedDelete = true
                                        disarmTimer.restart()
                                        return
                                    }
                                    sessRow.armedDelete = false
                                    root.provider.removeSession(sessRow.modelData.id)
                                }
                                Timer {
                                    id: disarmTimer
                                    interval: 3000
                                    onTriggered: sessRow.armedDelete = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

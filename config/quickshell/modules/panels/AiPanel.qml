import QtQuick
import QtQuick.Layouts
import qs.core
import qs.components
import qs.services
import qs.modules.settings

// Scalable Multi-Agent Dashboard: Uses modular AgentCard components with
// capability flags. All agents collapsed by default unless active/working.
ColumnLayout {
    id: root
    property real panelWidth: Theme.px(Config.v.panels.width)
    spacing: Theme.px(10)

    Component.onCompleted: {
        for (let i = 0; i < Ai.providers.length; i++) {
            if (Ai.providers[i].poll) {
                Ai.providers[i].poll()
            } else if (Ai.providers[i].refresh) {
                Ai.providers[i].refresh()
            }
        }
    }

    function setInhibit(v) {
        Settings.setPath(["ai", "suspendInhibit"], v)
    }

    // Header with Notification and Inhibit toggles (properly aligned)
    PanelHeader {
        icon: "smart_toy"
        title: "AI agents"

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            name: AiAntigravity.notifyOnDone ? "notifications_active" : "notifications_off"
            tone: AiAntigravity.notifyOnDone ? Theme.accent : Theme.textDim
            onClicked: {
                Settings.setPath(["ai", "notifyOnDone"], !AiAntigravity.notifyOnDone)
            }
        }

        Label {
            Layout.alignment: Qt.AlignVCenter
            text: "Inhibit"
            color: Theme.textDim
            font.pixelSize: Theme.fontSize - 1
        }

        Toggle {
            Layout.alignment: Qt.AlignVCenter
            checked: Ai.inhibitArmed
            onToggled: {
                root.setInhibit(!Ai.inhibitArmed)
            }
        }
    }

    // Global Status Summary
    Label {
        Layout.fillWidth: true
        color: Theme.textDim
        font.pixelSize: Theme.fontSize - 1
        text: {
            if (!Ai.running) return "No AI agents active"
            const busyCount = Ai.providers.filter(p => p.busy).length
            const waitCount = Ai.attention
            const parts = []
            if (busyCount > 0) parts.push(busyCount + " working")
            if (waitCount > 0) parts.push(waitCount + " waiting for you")
            return parts.length > 0 ? parts.join(" · ") : "All agents idle"
        }
    }

    // Dynamic Cards for all registered providers (Antigravity, OpenCode, Claude, Codex, Freebuff)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.px(8)

        Repeater {
            model: Ai.providers

            delegate: AgentCard {
                required property var modelData
                provider: modelData
                supportsResumption: true
                supportsDeletion: true
                supportsRequests: true
                supportsSessions: true
                supportsTelemetry: true
            }
        }
    }
}

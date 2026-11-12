import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.components
import qs.services

// Settings window: every key of config.json, edited here and saved to the file.
// Changes apply immediately. Open it from the control center or with: qsctl settings toggle
Scope {
    id: root
    readonly property bool want: Popups.open === "settings"
    property bool keep: false
    onWantChanged: { if (!want) { keep = true; kt.restart() } else keep = false }
    Timer { id: kt; interval: 300; onTriggered: root.keep = false }

    LazyLoader {
        active: root.want || root.keep
        OverlayWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Popups.screenName) ?? Quickshell.screens[0]
            open: root.want
            cardWidth: Theme.px(980)
            cardHeight: Theme.px(660)
            onCloseRequested: Popups.close()

            property string section: "general"
            property var sections: []
            property var rows: []

            function kindOf(p, v) {
                if (typeof v === "boolean") return "bool"
                if (typeof v === "number") return "num"
                if (typeof v === "string") return Settings.options(p) ? "enum" : "str"
                if (Array.isArray(v)) return v.every(x => typeof x === "string" || typeof x === "number") ? "list" : "json"
                return "json"
            }
            function isObj(v) { return v !== null && typeof v === "object" && !Array.isArray(v) }
            function flatten(obj, path, out, depth) {
                for (const k of Object.keys(obj)) {
                    const v = obj[k], p = path.concat([k])
                    if (isObj(v)) { out.push({ header: true, label: p.slice(depth).join("."), path: p, type: "" }); flatten(v, p, out, depth) }
                    else out.push({ header: false, label: p.slice(depth).join("."), path: p, type: kindOf(p, v) })
                }
            }
            function build() {
                const q = search.text.trim().toLowerCase()
                const v = Config.v, out = []
                if (q !== "") {
                    const all = []
                    for (const k of Object.keys(v)) {
                        if (k === "paletteSystem") continue
                        if (isObj(v[k])) flatten(v[k], [k], all, 0)
                        else all.push({ header: false, label: k, path: [k], type: kindOf([k], v[k]) })
                    }
                    rows = all.filter(r => !r.header && r.path.join(".").toLowerCase().includes(q))
                } else if (section === "general") {
                    for (const k of Object.keys(v))
                        if (!isObj(v[k]) && k !== "paletteSystem") out.push({ header: false, label: k, path: [k], type: kindOf([k], v[k]) })
                    rows = out
                } else {
                    flatten(v[section] ?? {}, [section], out, 1)
                    rows = out
                }
            }
            onSectionChanged: build()
            Component.onCompleted: {
                const v = Config.v, s = ["general"]
                for (const k of Object.keys(v)) if (isObj(v[k]) && k !== "paletteSystem") s.push(k)
                sections = s
                build()
                search.focusInput()
            }

            RowLayout {
                anchors { fill: parent; margins: Theme.px(16) }
                spacing: Theme.px(16)

                // ---- sections ----
                ColumnLayout {
                    Layout.preferredWidth: Theme.px(190)
                    Layout.fillHeight: true
                    spacing: Theme.px(10)
                    PanelHeader { icon: "settings"; title: "Settings" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: win.sections
                        delegate: Rectangle {
                            id: sd
                            required property string modelData
                            readonly property bool cur: win.section === modelData && search.text === ""
                            width: ListView.view.width
                            height: Theme.px(32)
                            radius: Theme.px(10)
                            color: cur ? Theme.accent : sh.hovered ? Theme.surface : "transparent"
                            HoverHandler { id: sh }
                            Label {
                                anchors { fill: parent; leftMargin: Theme.px(12) }
                                text: sd.modelData.charAt(0).toUpperCase() + sd.modelData.slice(1)
                                color: sd.cur ? Theme.accentText : Theme.text
                                font.weight: sd.cur ? Font.DemiBold : Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { search.text = ""; win.section = sd.modelData; win.build() }
                            }
                        }
                    }
                }

                // ---- values ----
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.px(10)
                    SearchField {
                        id: search
                        Layout.fillWidth: true
                        placeholder: "Search every setting"
                        onTextChanged: win.build()
                    }
                    ListView {
                        id: lv
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: win.rows
                        delegate: Item {
                            id: d
                            required property var modelData
                            width: ListView.view.width
                            height: modelData.header ? Theme.px(36) : Theme.px(40)
                            Label {
                                visible: d.modelData.header
                                anchors { left: parent.left; bottom: parent.bottom; leftMargin: Theme.px(6); bottomMargin: Theme.px(4) }
                                text: d.modelData.label.toUpperCase()
                                color: Theme.accent
                                font.pixelSize: Theme.fontSize - 2
                                font.letterSpacing: 1.5
                            }
                            RowLayout {
                                visible: !d.modelData.header
                                anchors { fill: parent; leftMargin: Theme.px(6); rightMargin: Theme.px(6) }
                                spacing: Theme.px(12)
                                Label { Layout.fillWidth: true; text: d.modelData.label; elide: Text.ElideRight }
                                Loader {
                                    Component.onCompleted: {
                                        const t = d.modelData.type
                                        if (t === "") return
                                        setSource(t === "bool" ? "SettingBool.qml" : t === "num" ? "SettingNum.qml"
                                            : t === "enum" ? "SettingEnum.qml" : t === "list" ? "SettingList.qml"
                                            : t === "json" ? "SettingJson.qml" : "SettingStr.qml", { row: d.modelData })
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        text: "Saved to config.json and applied right away. Esc closes."
                        color: Theme.textFaint
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }
}

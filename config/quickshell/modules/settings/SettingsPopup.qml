import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core
import qs.components
import qs.services

// Settings window. It reads config.json and shows the right control for each key: toggles,
// sliders, pickers for installed fonts / cursors / icon themes / colour names, a file and
// folder browser, a colour picker, and monitor chips. Every change is saved to config.json
// and applies at once. Open it from the control center or with: qsctl settings toggle
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
            cardWidth: Theme.px(1000)
            cardHeight: Theme.px(680)

            property string section: "general"
            property var sections: []
            property var rows: []
            property var choiceSpec: null
            property var colorSpec: null
            property var fileSpec: null
            readonly property bool dialogOpen: choiceSpec !== null || colorSpec !== null || fileSpec !== null
            readonly property string home: Quickshell.env("HOME")

            function closeDialogs() { choiceSpec = null; colorSpec = null; fileSpec = null }
            onCloseRequested: { if (dialogOpen) closeDialogs(); else Popups.close() }

            Connections {
                target: Settings
                function onChoiceRequested(spec) { win.closeDialogs(); win.choiceSpec = spec; cs.text = ""; cs.focusInput() }
                function onColorRequested(spec) { win.closeDialogs(); win.colorSpec = spec; colorCard.load(spec.current) }
                function onFileRequested(spec) {
                    win.closeDialogs(); win.fileSpec = spec
                    let p = (spec.current || "").replace(/^~/, win.home)
                    if (!spec.dir && p !== "") p = p.replace(/\/[^\/]*$/, "")
                    fileCard.go(p !== "" ? p : win.home)
                }
            }

            // ---------- building the list of settings ----------
            function isObj(v) { return v !== null && typeof v === "object" && !Array.isArray(v) }
            function rowFor(path, label, value, extra) {
                return Object.assign({ header: false, label: label, path: path, spec: Settings.describe(path, value) }, extra || {})
            }
            function flatten(obj, path, out, depth) {
                for (const k of Object.keys(obj)) {
                    const v = obj[k], p = path.concat([k])
                    if (isObj(v)) { out.push({ header: true, label: p.slice(depth).join("."), path: p }); flatten(v, p, out, depth) }
                    else out.push(rowFor(p, p.slice(depth).join("."), v))
                }
            }
            function build() {
                const q = search.text.trim().toLowerCase()
                const v = Config.v, out = []
                const skip = k => k === "paletteSystem" || k === "palettes"
                if (q !== "") {
                    const all = []
                    for (const k of Object.keys(v)) {
                        if (skip(k)) continue
                        if (isObj(v[k])) flatten(v[k], [k], all, 0)
                        else all.push(rowFor([k], k, v[k]))
                    }
                    rows = all.filter(r => !r.header && r.path.join(".").toLowerCase().includes(q))
                } else if (section === "general") {
                    for (const k of Object.keys(v)) if (!isObj(v[k]) && !skip(k)) out.push(rowFor([k], k, v[k]))
                    rows = out
                } else if (section === "palettes") {
                    // a wallpaper and a cursor for each palette; empty means "leave unchanged"
                    for (const p of Theming.palettes) {
                        out.push({ header: true, label: p.name, path: ["palettes", p.name] })
                        out.push(rowFor(["palettes", p.name, "wallpaper"], "Wallpaper", "", { hint: p.wallpaper }))
                        out.push(rowFor(["palettes", p.name, "cursor"], "Cursor theme", "", { hint: p.cursor }))
                    }
                    rows = out
                } else {
                    flatten(v[section] ?? {}, [section], out, 1)
                    rows = out
                }
            }
            onSectionChanged: build()
            Component.onCompleted: {
                const v = Config.v, s = ["general", "palettes"]
                for (const k of Object.keys(v)) if (isObj(v[k]) && k !== "paletteSystem" && k !== "palettes") s.push(k)
                sections = s
                build()
                search.focusInput()
            }

            // ---------- layout ----------
            RowLayout {
                anchors { fill: parent; margins: Theme.px(16) }
                spacing: Theme.px(16)

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
                                        if (d.modelData.header) return
                                        const k = d.modelData.spec.kind
                                        setSource(k === "bool" ? "SettingBool.qml" : k === "num" ? "SettingNum.qml"
                                            : k === "slider" ? "SettingSlider.qml" : k === "enum" ? "SettingEnum.qml"
                                            : k === "choice" ? "SettingChoice.qml" : (k === "image" || k === "dir") ? "SettingFile.qml"
                                            : k === "color" ? "SettingColor.qml" : k === "monitors" ? "SettingMonitors.qml"
                                            : k === "list" ? "SettingList.qml" : k === "json" ? "SettingJson.qml" : "SettingStr.qml",
                                            { row: d.modelData })
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

            // ---------- dialogs ----------
            Rectangle {
                anchors.fill: parent
                radius: Theme.px(Config.v.panels.radius)
                color: Qt.rgba(0, 0, 0, 0.55)
                opacity: win.dialogOpen ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 140 } }
                MouseArea { anchors.fill: parent; onClicked: win.closeDialogs() }
            }

            // pick from a list
            Rectangle {
                id: choiceCard
                visible: win.choiceSpec !== null
                anchors.centerIn: parent
                width: Theme.px(440); height: Theme.px(520)
                radius: Theme.px(18)
                color: Theme.panel
                border.width: 1; border.color: Theme.surfaceHi
                readonly property var spec: win.choiceSpec ? win.choiceSpec.spec : null
                readonly property bool isFont: spec !== null && spec.choices === "font"
                readonly property bool isColor: spec !== null && spec.choices === "colorname"
                readonly property var opts: spec ? Settings.choices(spec) : []
                readonly property var shown: {
                    const q = cs.text.trim().toLowerCase()
                    return q === "" ? opts : opts.filter(o => o.toLowerCase().includes(q))
                }
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.px(14) }
                    spacing: Theme.px(10)
                    PanelHeader { icon: "list"; title: win.choiceSpec ? win.choiceSpec.title : "" }
                    SearchField { id: cs; Layout.fillWidth: true; placeholder: "Search" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        header: Item {
                            width: ListView.view.width
                            height: choiceCard.spec && choiceCard.spec.empty ? Theme.px(34) : 0
                            visible: height > 0
                            ListItem {
                                anchors.fill: parent
                                text: choiceCard.spec && choiceCard.spec.emptyLabel ? choiceCard.spec.emptyLabel : "Default"
                                active: win.choiceSpec !== null && win.choiceSpec.current === ""
                                onClicked: { win.choiceSpec.pick(""); win.closeDialogs() }
                            }
                        }
                        Label {
                            visible: choiceCard.opts.length === 0
                            anchors.centerIn: parent
                            text: "Loading..."
                            color: Theme.textDim
                        }
                        model: choiceCard.shown
                        delegate: Rectangle {
                            id: od
                            required property string modelData
                            readonly property bool cur: win.choiceSpec !== null && win.choiceSpec.current === modelData
                            width: ListView.view.width
                            height: Theme.px(34)
                            radius: Theme.px(10)
                            color: cur || oh.hovered ? Theme.surface : "transparent"
                            HoverHandler { id: oh }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.choiceSpec.pick(od.modelData); win.closeDialogs() }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
                                spacing: Theme.px(10)
                                Rectangle {
                                    visible: choiceCard.isColor
                                    implicitWidth: Theme.px(16); implicitHeight: implicitWidth; radius: width / 2
                                    color: Config.v.colors[od.modelData] ?? "transparent"
                                    border.width: 1; border.color: Qt.alpha(Theme.text, 0.25)
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: od.modelData
                                    elide: Text.ElideRight
                                    font.family: choiceCard.isFont ? od.modelData : Theme.fontFamily
                                }
                                Icon { visible: od.cur; name: "check"; size: Theme.px(14); color: Theme.accent }
                            }
                        }
                    }
                }
            }

            // pick a colour: three sliders and a hex box, live
            Rectangle {
                id: colorCard
                visible: win.colorSpec !== null
                anchors.centerIn: parent
                width: Theme.px(400); height: Theme.px(340)
                radius: Theme.px(18)
                color: Theme.panel
                border.width: 1; border.color: Theme.surfaceHi
                property real h: 0
                property real s: 0
                property real v: 0
                readonly property color out: Qt.hsva(h, s, v, 1)
                function hexOf(c) {
                    const t = x => Math.round(x * 255).toString(16).padStart(2, "0")
                    return "#" + t(c.r) + t(c.g) + t(c.b)
                }
                function load(hex) {
                    const c = Qt.color(hex)
                    h = c.hsvHue < 0 ? 0 : c.hsvHue; s = c.hsvSaturation; v = c.hsvValue
                }
                function emit() { if (win.colorSpec) win.colorSpec.pick(hexOf(Qt.hsva(h, s, v, 1))) }
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.px(16) }
                    spacing: Theme.px(12)
                    PanelHeader { icon: "palette"; title: win.colorSpec ? win.colorSpec.title : "" }
                    RowLayout {
                        spacing: Theme.px(12)
                        Rectangle { implicitWidth: Theme.px(64); implicitHeight: Theme.px(64); radius: Theme.px(16); color: colorCard.out; border.width: 1; border.color: Qt.alpha(Theme.text, 0.25) }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Theme.px(34); radius: Theme.px(10); color: Theme.surface
                            border.width: hex.activeFocus ? 1 : 0; border.color: Theme.accent
                            TextInput {
                                id: hex
                                anchors { fill: parent; leftMargin: Theme.px(12); rightMargin: Theme.px(12) }
                                verticalAlignment: Text.AlignVCenter
                                text: colorCard.hexOf(colorCard.out)
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 1
                                selectByMouse: true
                                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) { colorCard.load(text); colorCard.emit() }
                            }
                        }
                    }
                    Repeater {
                        model: [{ n: "Hue", k: "h" }, { n: "Saturation", k: "s" }, { n: "Brightness", k: "v" }]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.px(10)
                            Label { text: modelData.n; Layout.preferredWidth: Theme.px(90); color: Theme.textDim }
                            Slider {
                                Layout.fillWidth: true
                                thickness: Theme.px(8)
                                value: colorCard[modelData.k]
                                onMoved: v => { colorCard[modelData.k] = v; colorCard.emit() }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // browse for a file or folder
            Rectangle {
                id: fileCard
                visible: win.fileSpec !== null
                anchors.centerIn: parent
                width: Theme.px(600); height: Theme.px(560)
                radius: Theme.px(18)
                color: Theme.panel
                border.width: 1; border.color: Theme.surfaceHi
                property string path: ""
                property var entries: []
                readonly property bool dirMode: win.fileSpec !== null && win.fileSpec.dir === true
                readonly property var imgRe: /\.(png|jpe?g|webp|bmp|gif)$/i
                function go(p) { path = p === "" ? "/" : p; ls.running = true }
                function up() { go(path.replace(/\/[^\/]+\/?$/, "")) }
                function tilde(p) { return p.startsWith(win.home) ? "~" + p.slice(win.home.length) : p }
                Process {
                    id: ls
                    command: ["sh", "-c", 'cd "$1" 2>/dev/null && ls -1Ap --group-directories-first', "_", fileCard.path]
                    stdout: StdioCollector {
                        onStreamFinished: fileCard.entries = text.split("\n").filter(x => x !== "" && !x.startsWith(".")
                            && (x.endsWith("/") || (!fileCard.dirMode && (win.fileSpec && win.fileSpec.dir === false ? true : fileCard.imgRe.test(x)))))
                    }
                }
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors { fill: parent; margins: Theme.px(14) }
                    spacing: Theme.px(10)
                    PanelHeader { icon: fileCard.dirMode ? "folder" : "image"; title: win.fileSpec ? win.fileSpec.title : "" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.px(6)
                        IconButton { name: "arrow_upward"; onClicked: fileCard.up() }
                        IconButton { name: "home"; onClicked: fileCard.go(win.home) }
                        IconButton { name: "photo_library"; onClicked: fileCard.go(win.home + "/Pictures") }
                        Label { Layout.fillWidth: true; text: fileCard.tilde(fileCard.path); color: Theme.textDim; elide: Text.ElideLeft }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: fileCard.entries
                        delegate: Rectangle {
                            id: fd
                            required property string modelData
                            readonly property bool isDir: modelData.endsWith("/")
                            readonly property string name: isDir ? modelData.slice(0, -1) : modelData
                            readonly property bool isImg: fileCard.imgRe.test(modelData)
                            width: ListView.view.width
                            height: isImg ? Theme.px(44) : Theme.px(34)
                            radius: Theme.px(10)
                            color: fh.hovered ? Theme.surface : "transparent"
                            HoverHandler { id: fh }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const full = (fileCard.path === "/" ? "" : fileCard.path) + "/" + fd.name
                                    if (fd.isDir) fileCard.go(full)
                                    else { win.fileSpec.pick(fileCard.tilde(full)); win.closeDialogs() }
                                }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
                                spacing: Theme.px(10)
                                Item {
                                    implicitWidth: Theme.px(52); implicitHeight: Theme.px(30)
                                    Image {
                                        visible: fd.isImg
                                        anchors.fill: parent
                                        source: fd.isImg ? "file://" + (fileCard.path === "/" ? "" : fileCard.path) + "/" + fd.name : ""
                                        asynchronous: true; cache: false
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 104
                                    }
                                    Icon { visible: !fd.isImg; anchors.centerIn: parent; name: fd.isDir ? "folder" : "draft"; color: fd.isDir ? Theme.accent : Theme.textDim }
                                }
                                Label { Layout.fillWidth: true; text: fd.name; elide: Text.ElideRight }
                            }
                        }
                    }
                    ActionButton {
                        visible: fileCard.dirMode
                        Layout.fillWidth: true
                        implicitHeight: Theme.px(40)
                        icon: "check"; text: "Choose this folder"; active: true
                        onClicked: { win.fileSpec.pick(fileCard.tilde(fileCard.path)); win.closeDialogs() }
                    }
                }
            }
        }
    }
}

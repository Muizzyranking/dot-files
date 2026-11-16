pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.core

Singleton {
    id: root
    property string pinned: ""
    property var dismissedKeys: []
    readonly property var players: Mpris.players ? Array.from(Mpris.players.values) : []
    function key(p) { return p.dbusName || p.identity || "" }
    function excluded(p) {
        const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase()
        const tt = ((p.trackTitle || "") + " " + (p.trackArtist || "")).toLowerCase()
        return Config.v.media.exclude.some(s => id.includes(String(s).toLowerCase()))
            || Config.v.media.excludeTitles.some(s => tt.includes(String(s).toLowerCase()))
    }
    readonly property var usable: players.filter(p => !excluded(p) && !dismissedKeys.includes(key(p)))
    readonly property var islandPlayer: usable.find(p => p.isPlaying) ?? null
    readonly property bool active: islandPlayer !== null
    // players exist at all (even paused): an expanded music view stays open on this
    readonly property bool present: usable.length > 0
    readonly property var player: usable.find(p => key(p) === pinned) ?? islandPlayer ?? usable[0] ?? null

    function select(p) { pinned = key(p) }
    function closeSource(p) {
        const k = key(p)
        if (pinned === k) pinned = ""
        if (p.canQuit && !k.toLowerCase().includes("chrom")) p.quit()
        else if (p.isPlaying && p.canPause) p.togglePlaying()
        if (!dismissedKeys.includes(k)) dismissedKeys = dismissedKeys.concat([k])
    }

    Timer {
        running: root.dismissedKeys.length > 0
        interval: 1000; repeat: true
        onTriggered: {
            const keep = root.dismissedKeys.filter(k => {
                const q = root.players.find(x => root.key(x) === k)
                return !(q && q.isPlaying)
            })
            if (keep.length !== root.dismissedKeys.length) root.dismissedKeys = keep
        }
    }
}

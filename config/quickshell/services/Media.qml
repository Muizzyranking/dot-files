pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.core

// Players: config "media.exclude" skips players by name (like "chrome"), "media.excludeTitles"
// by track text. The island follows whatever is actually playing. The control center can
// pin one source to look at; closing a source quits it (or stops it if it cannot quit).
Singleton {
    property string pinned: ""
    readonly property var players: Mpris.players ? Array.from(Mpris.players.values) : []
    function key(p) { return p.dbusName || p.identity || "" }
    function excluded(p) {
        const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase()
        const tt = ((p.trackTitle || "") + " " + (p.trackArtist || "")).toLowerCase()
        return Config.v.media.exclude.some(s => id.includes(String(s).toLowerCase()))
            || Config.v.media.excludeTitles.some(s => tt.includes(String(s).toLowerCase()))
    }
    readonly property var usable: players.filter(p => !excluded(p))
    readonly property var islandPlayer: usable.find(p => p.isPlaying) ?? null
    readonly property bool active: islandPlayer !== null
    readonly property var player: usable.find(p => key(p) === pinned) ?? islandPlayer ?? usable[0] ?? null

    function select(p) { pinned = key(p) }
    function closeSource(p) {
        if (pinned === key(p)) pinned = ""
        if (p.canQuit) p.quit(); else p.stop()
    }
}

//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.wallpaper
import qs.modules.clipboard
import qs.modules.capture
import qs.modules.launcher
import qs.modules.lock
import qs.modules.settings
import qs.modules.ipc
import qs.services

ShellRoot {
    WallpaperWindow {}
    Bar {}
    ClipboardPopup {}
    WallpaperPicker {}
    LauncherWindow {}
    RegionSelector {}
    LockScreen {}
    SettingsPopup {}
    Ipc {}
    Component.onCompleted: { Sounds.init(); Theming.names }
}

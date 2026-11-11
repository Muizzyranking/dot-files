pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property BacklightDevice screen: BacklightDevice { match: "" }
    readonly property BacklightDevice keys: BacklightDevice { match: "*kbd_backlight*"; minValue: 0 }
}

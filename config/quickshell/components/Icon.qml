import QtQuick
import qs.core

// Material Symbols icon by ligature name, e.g. Icon { name: "wifi" }
Text {
    property string name: ""
    property real size: Theme.iconSize
    text: name
    color: Theme.text
    font.family: Theme.iconFamily
    font.variableAxes: ({ "FILL": Config.v.font.iconFill, "wght": Config.v.font.iconWeight })
    font.pixelSize: size
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    Behavior on color { ColorAnimation { duration: Config.v.animation.fast } }
}

import QtQuick
import qs

// "|" mellem grupper -- var custom/sep i waybar.
Text {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    text: "|"
    color: Theme.color5
    font.family: Config.fontFamily
    font.pixelSize: Config.fontSize
    renderType: Text.NativeRendering
    leftPadding: Theme.itemPadding
    rightPadding: Theme.itemPadding
}

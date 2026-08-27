import QtQuick
import qs
import qs.widgets

// Waybars tooltips: en blok monospace-tekst med linjeskift bevaret.
Popup {
    id: root

    property string text: ""

    Text {
        text: root.text
        textFormat: Text.PlainText
        color: Theme.foreground
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
        lineHeight: 1.15
    }
}

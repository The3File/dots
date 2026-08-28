import QtQuick
import qs

// Teksten i en raekke i en menu. Ligger som widget og ikke inde i den enkelte
// flade, saa menuen, aabneren og beskederne ikke kan drifte fra hinanden i
// skriftstoerrelse eller afkortning.
Text {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    elide: Text.ElideRight
    font.family: Config.fontFamily
    font.pixelSize: Config.fontSize
    renderType: Text.NativeRendering
}

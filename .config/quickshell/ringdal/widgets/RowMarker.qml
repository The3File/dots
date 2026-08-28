import QtQuick
import qs

// Markeringen bag en raekke. Musen og tastaturet peger paa det samme, saa de
// to maader at vaelge paa maa ogsaa se ens ud.
Rectangle {
    property bool hovered: false
    property bool selected: false

    anchors.fill: parent
    radius: 4
    color: selected ? Theme.color0 : (hovered ? Theme.color0 : "transparent")
    opacity: selected ? 1 : (hovered ? 0.6 : 0)

    Behavior on opacity { NumberAnimation { duration: 90 } }
}

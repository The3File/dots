import QtQuick
import qs.widgets

// Broen mellem en service og baren. Alle scriptbaserede moduler ser ens ud
// herfra, saa der ikke skal vedligeholdes ni naesten-ens filer.
BarItem {
    id: root

    required property var service

    text: service.text
    color: service.color
    underline: service.underline
    visible: service.visible && text !== ""

    // Modulerne uden tooltip sender tom streng, og saa dukker der ingenting op.
    property string tooltipText: service.tooltip ?? ""

    InfoPanel {
        target: root
        text: root.tooltipText
        visible: root.hovered && root.tooltipText !== ""
    }
}

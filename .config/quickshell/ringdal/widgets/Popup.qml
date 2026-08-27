import QtQuick
import Quickshell
import qs

// Faelles popup-flade. Bygges nu, fordi det er samme maskine der senere skal
// baere perf-menuen, netvaerksvaelgeren, OSD'erne og notifikationerne -- ikke
// fordi tooltips i sig selv kraever den.
//
// Baren staar i bunden, saa en popup vokser opad fra modulet den hoerer til.
PopupWindow {
    id: root

    // Modulet popuppen hoerer til. Placeringen foelger det.
    property Item target: null
    // Saet true naar popuppen skal kunne tage imod tastetryk (menuer senere).
    property bool takesFocus: false

    default property alias content: container.data

    anchor.item: target
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.margins.bottom: 4
    // Moduler yderst til hoejre (uret) skubbes ind paa skaermen i stedet for at
    // vende paa hovedet.
    anchor.adjustment: PopupAdjustment.SlideX

    grabFocus: takesFocus
    color: "transparent"

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    Rectangle {
        id: frame
        anchors.fill: parent
        // Samme rice som alacritty, fuzzel og baren: ugennemsigtig sort,
        // skarpe hjoerner, kant i color4.
        color: Theme.barBackground
        border.width: 1
        border.color: Theme.color4
        radius: 0

        readonly property int padding: Theme.itemPadding

        implicitWidth: container.implicitWidth + 2 * padding + 2 * border.width
        implicitHeight: container.implicitHeight + 2 * padding + 2 * border.width

        Item {
            id: container
            anchors {
                fill: parent
                margins: frame.padding + frame.border.width
            }
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}

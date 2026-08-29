import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.widgets

// "Hvad laver den?" -- det mellemste trin paa stigen.
//
// Stigen gik foer fra en prik paa syv pixels direkte til hele terminalen paa
// tusind. Det her er trinnet imellem: et par linjer om hvad sessionen er i
// gang med, og hvor laenge den har vaeret det.
//
// Den bor i OUTPUT-pillen. Foerste udgave laa i kroppens menu som fjorten
// raekker raa terminaltekst, og det var forkert to gange: menuens raekker er
// én linje der klippes af i hoejre side, saa alt af laengde blev ulaeseligt --
// og menuen er kroppen, altsaa det Filip putter IND. Hvad maskinen laver, er
// noget den giver ham.
//
// Derfor ombrydes der her, og derfor er der faa linjer. Detaljen staar i
// terminalen, ét tastetryk vaek (Super+A); den skal ikke tegnes efter i QML.
Item {
    id: root

    readonly property var lines: Agent.lines

    implicitWidth: Config.notifyWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4

        // Overskriften er ogsaa vejen ud -- naar fladen staar aaben, er
        // prikken gemt bag den, saa der er ikke noget at klikke paa igen.
        // Samme greb som beskedlisten bruger.
        Item {
            width: parent.width
            height: Config.fontSize + 12

            RowMarker { hovered: lukHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: tilstand.left
                anchors.rightMargin: Config.restSpacing
                text: "‹ Claude"
                color: Theme.color5
            }

            RowLabel {
                id: tilstand
                anchors.right: parent.right
                width: Math.min(implicitWidth, parent.width * 0.4)
                horizontalAlignment: Text.AlignRight
                text: Agent.state
                color: Agent.color
            }

            MouseArea {
                id: lukHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Agent.hide()
            }
        }

        Repeater {
            model: root.lines

            // Ombrydes, ikke klippes. Det var hele fejlen i foerste udgave.
            Text {
                required property var modelData
                required property int index

                width: col.width
                text: modelData
                wrapMode: Text.WordWrap
                // "i gang: 3m 26s" er ikke noget den har lavet, det er uret.
                // Daempet, saa oejet finder handlingerne foerst.
                color: String(modelData).startsWith("i gang:")
                    ? Theme.color8 : Theme.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
            }
        }

        Text {
            width: parent.width
            visible: root.lines.length === 0
            text: "kigger…"
            color: Theme.color8
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            renderType: Text.NativeRendering
        }

        // Vejen videre, naar de faa linjer ikke raekker. Den staar her i
        // stedet for at skulle huskes: Super+A er terminalen selv.
        Item {
            width: parent.width
            height: Config.fontSize + 12

            RowMarker { hovered: aabnHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "åbn terminalen"
                color: Theme.color8
            }

            MouseArea {
                id: aabnHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: { Agent.hide(); aabn.running = true; }
            }
        }
    }

    // Praecis den vej Super+A tager -- ét sted, ikke to. `scratch` kender
    // selv baade at hente frem og at starte, hvis der ikke er noget at hente.
    Process {
        id: aabn
        command: [`${Config.home}/.Scripts/scratch`, "aios"]
    }
}

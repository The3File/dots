import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.services

// Beskeden, mens den er ny. Tre linjer paa det hoejeste: hvem, hvad, og lidt
// mere hvis der er noget.
//
// Ingen knapper. Klik goer det aabenlyse -- foerste handling hvis beskeden
// har en, ellers luk. Hoejreklik lukker altid. Det er hurtigere end at ramme
// et kryds paa 12 pixels i et hjoerne.
Item {
    id: root

    readonly property var n: Notifs.latest

    implicitWidth: Config.notifyWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4

        Line {
            text: root.n ? root.n.appName : ""
            color: Notifs.critical ? Theme.stateBad : Theme.color5
        }

        Line {
            text: root.n ? Markup.strip(root.n.summary) : ""
            color: Theme.foreground
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }

        Line {
            visible: text !== ""
            text: root.n ? Markup.strip(root.n.body) : ""
            color: Theme.color8
            wrapMode: Text.Wrap
            maximumLineCount: 3
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // Bundet til om musen ER paa boblen -- ikke til at den kom ind én
        // gang. Et enter uden et exit (formen skifter under en markoer der
        // staar stille) lod ellers `held` staa tilbage som sand, og saa
        // holdt den boblen aabnet uden at nogen holdt paa den.
        onContainsMouseChanged: Notifs.held = hover.containsMouse
        Component.onDestruction: Notifs.held = false

        onClicked: event => {
            Notifs.held = false;
            if (event.button === Qt.RightButton) Notifs.dismiss(root.n);
            else Notifs.act(root.n);
        }
    }

    // Egen tekst-komponent i stedet for RowLabel: her staar linjerne under
    // hinanden i en Column, og RowLabel centrerer sig selv lodret -- det maa
    // man ikke inde i en Column.
    component Line: Text {
        width: col.width
        elide: Text.ElideRight
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }
}

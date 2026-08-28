import QtQuick
import Quickshell
import qs
import qs.services

// Spoergsmaalet om root-adgang, mens det staar. Samme form som en besked, og
// af samme grund: det er noget der sker for Filip, ikke noget han er i gang
// med, og det maa ikke skubbe kroppen til side.
//
// Ingen ja-knap. Fingeren er svaret, og der findes ikke et klik der giver
// root -- man kan kun sige nej her. Hoejreklik afviser, praecis som paa en
// besked; venstreklik goer med vilje ingenting.
//
// Kommandoen staar ordret. Det er hele grunden til at spoerge, saa den maa
// hverken forkortes eller skrives om.
Item {
    id: root

    implicitWidth: Config.notifyWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4

        Line {
            text: "root-adgang"
            color: Theme.color5
        }

        Line {
            text: Sudo.cmd
            color: Theme.foreground
            wrapMode: Text.Wrap
            maximumLineCount: 3
        }

        Line {
            text: Sudo.accepted ? "godkendt" : "roer laeseren"
            color: Sudo.accepted ? Theme.stateGood : Theme.color8
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Sudo.besvar("nej")
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

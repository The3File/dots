import QtQuick
import Quickshell
import qs
import qs.services

// Afvigelserne. En lille pille ved siden af kroppen, der kun findes naar noget
// ikke er som det plejer -- og som slet ikke fylder naar alt er normalt.
//
// Det er samme regel koffein altid har fulgt, sat i system: tastaturlaasen,
// nettet og koffein staar ikke og fortaeller at alt er i orden. De siger til,
// naar det ikke er.
Item {
    id: root

    readonly property bool locked: Keylock.locked
    readonly property bool offline: Net.visible && !Net.connected
    readonly property bool awake: Koffein.visible
    // Beskeder der stadig ligger. De hoerer til her og ikke i hvilen: er der
    // ingen, skal der ikke staa "0 beskeder" og fylde.
    readonly property int waiting: Notifs.count
    // Claude har brug for ham. Staar her og ikke i kroppen, saa den ikke kan
    // skjules af en aaben menu eller af at han dikterer.
    readonly property bool asking: Agent.waiting

    readonly property bool any: locked || offline || awake || asking || waiting > 0

    implicitWidth: any ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        // IKKE centerIn: parent -- forældrens bredde kommer FRA raekken,
        // saa det ville vaere en rundkreds og begge dele blev nul.
        spacing: Config.restSpacing

        Label {
            text: "låst"
            color: Theme.stateBad
            visible: root.locked
        }

        Label {
            text: "intet net"
            color: Theme.stateBad
            visible: root.offline
        }

        Label {
            text: "venter"
            color: Theme.stateWarn
            visible: root.asking
        }

        Label {
            text: "koffein"
            color: Theme.stateWarn
            visible: root.awake
        }

        Label {
            text: root.waiting === 1 ? "1 besked" : `${root.waiting} beskeder`
            color: Theme.color5
            visible: root.waiting > 0

            MouseArea {
                anchors.fill: parent
                onClicked: Pill.notifs()
            }
        }
    }

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }
}

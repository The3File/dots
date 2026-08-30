import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

// Hvad kroppen viser naar der ikke sker noget. Fire ting, og de tre af dem er
// der ikke altid.
//
// Reglen bag udvalget: et modul fortjener sin faste plads kun hvis det aendrer
// sig ofte nok til at vaere vaerd at kigge paa, OG Filip ville goere noget
// anderledes naar han saa det aendre sig. Ydelse, volumen og lysstyrke faldt
// paa det andet led -- han hoerte eller saa det allerede selv, da han aendrede
// det. De kommer tilbage som tilstande i kroppen, ikke som tekst der staar
// fremme.
Item {
    id: root

    required property ShellScreen bodyScreen

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bodyScreen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    // Sandt mens pladsen aabner eller lukker sig. Kroppen slaar sin egen
    // bredde-animation fra saa laenge -- se kommentaren i Body.qml.
    readonly property bool wsMoving: visInd.running || visUd.running

    // Arbejdsrummet staar ikke fremme. Det bekraefter kort at du skiftede, og
    // gaar igen -- du har det alligevel i hovedet.
    //
    // To bevaegelser, aldrig samtidig: FORMEN foerst, TALLET bagefter. Foer
    // fadede de sammen, og saa stod tallet og blev laesbart i en kant der
    // endnu skubbede sig udad -- bevaegelsen kom fra to steder paa én gang.
    // Pillen goer plads; saa lander tallet i pladsen. Ud gaar det modsat.
    //
    // Derfor eksplicitte animationer og ikke to Behaviors med en pause foran:
    // pausens laengde skulle da laese det samme flag, som netop har udloest
    // animationen, og raekkefoelgen paa de to bindinger bestemmer vi ikke.
    onActiveIdChanged: {
        if (activeId < 0) return;
        hideWorkspace.stop();
        visUd.stop();
        visInd.restart();
    }

    SequentialAnimation {
        id: visInd
        NumberAnimation {
            target: wsSlot
            property: "plads"
            to: 1
            duration: Config.morphDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: wsSlot
            property: "tal"
            to: 1
            duration: Config.morphDuration
        }
        // Ventetiden begynder foerst naar tallet ER inde. Talte den fra
        // skiftet, aad indfoldningen af den tid, tallet stod stille.
        onFinished: hideWorkspace.restart()
    }

    // Ud gaar det IKKE i to trin. Raekkefoelgen betyder kun noget paa vejen
    // ind, hvor pladsen skal vaere der, foer tallet kan lande i den -- paa
    // vejen ud er der ingen, der laeser tallet. Fadede det foerst faerdigt,
    // stod pillen 320 ms aaben og tom og lukkede saa i ét ryk: stilstand og
    // derefter fuld fart er praecis det, oejet kalder et hak.
    //
    // Derfor samtidig, og med en kurve der starter i ro (InOutCubic i stedet
    // for OutCubic, som er hurtigst i foerste oejeblik). Tallet er vaek foer
    // pladsen naar at klippe det.
    ParallelAnimation {
        id: visUd
        NumberAnimation {
            target: wsSlot
            property: "tal"
            to: 0
            duration: Config.morphDuration / 3
        }
        NumberAnimation {
            target: wsSlot
            property: "plads"
            to: 0
            duration: Config.morphDuration
            easing.type: Easing.InOutCubic
        }
    }

    Timer {
        id: hideWorkspace
        interval: Config.workspaceLinger
        repeat: false
        onTriggered: visUd.restart()
    }

    Row {
        id: row
        // IKKE centerIn: parent -- forældrens bredde kommer FRA raekken,
        // saa det ville vaere en rundkreds og begge dele blev nul.
        //
        // INTET mellemrum her, og det er hele pointen: **en Row springer et
        // barn med bredde 0 helt over -- ogsaa dets spacing.** Laa
        // mellemrummet paa den her raekke, forsvandt det i ÉT spring i samme
        // oejeblik pladsen til arbejdsrumstallet ramte nul, og linjen er
        // centreret, saa ur og batteri hakkede en halv mellemrumsbredde til
        // venstre og gled derefter langsomt tilbage, mens kroppen indhentede.
        // (Vejen ind var fri af det: dér er bredde-animationen slaaet fra, saa
        // formen fulgte springet med det samme.)
        //
        // Pladsen baerer derfor selv sit mellemrum, og saa gaar den jaevnt
        // hele vejen til nul.
        spacing: 0

        // `plads` og `tal` skrues af visInd/visUd ovenfor. De er bindinger paa
        // width og opacity -- ingen animation staar direkte paa de to, for en
        // animation som vaerdikilde slaar bindingen tavst ihjel.
        Item {
            id: wsSlot

            property real plads: 0
            property real tal: 0

            width: wsSlot.plads * (ws.implicitWidth + Config.restSpacing)
            height: linje.height
            clip: true

            Label {
                id: ws
                anchors.verticalCenter: parent.verticalCenter
                text: root.activeId
                color: Theme.color4
                opacity: wsSlot.tal
            }
        }

        Row {
            id: linje
            spacing: Config.restSpacing

            Label {
                text: (Battery.charging ? "+" : "") + Battery.shortText
                color: Theme.rampColor(Battery.percent)
                visible: Battery.ready
            }

            Label {
                text: Clock.shortText
                color: Theme.foreground
            }
        }
    }

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        // Terminus er en bitmap-font; uden det her udglatter Qt den til
        // uskarphed.
        renderType: Text.NativeRendering
    }
}

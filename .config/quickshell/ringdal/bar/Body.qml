import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.widgets

// Kroppen. Ét element der skifter form efter hvad der sker -- ikke en bar med
// bobler haengt paa. Alle flader er tilstande her, ikke nye vinduer.
//
// Tilstandene, i den raekkefoelge de vinder over hinanden:
//
//   stemme   dikteringen koerer. Modal -- den skal ikke kunne skubbes vaek.
//   aabner   Super+D. Har tastaturet, saa den staar over alt andet du kunne
//            komme til at ramme -- men ikke over stemmen.
//   aaben    du klikkede. Bliver staaende til du gaar ud af den.
//   niveau   du skruede paa lyd eller lys. Kort, og kun bredere.
//   kig      musen blev haengende. Passiv -- viser mere, goer intet.
//   hvile    klokken og batteriet.
//
// Kroppen er INPUT: det Filip putter ind i maskinen -- stemmen, menuen,
// aabneren. Output -- beskeder og agenten -- bor i pillen ved siden af. Uden
// den opdeling bliver det uklart hvad der er hans, og hvad der er maskinens.
//
// Kig og aaben er skilt ad med vilje: pillen ligger i det hjoerne musen kommer
// forbi hele tiden, og en flade der aabner sig uopfordret er vaerre end ingen
// flade. At komme forbi og at ville noget skal ikke betyde det samme.
Item {
    id: root

    required property ShellScreen bodyScreen
    required property var hostWindow

    // Tilstanden bor i Pill-servicen, saa den er ens paa alle skaerme og kan
    // kaldes udefra.
    readonly property bool opened: Pill.opened
    readonly property bool _peeking: Pill.peeking

    readonly property string phase: {
        if (Voice.thinking || Voice.failed) return "thinking";
        if (Voice.listening || Voice.paused) return "listening";
        if (Launcher.active) return "launch";
        if (root.opened) return "open";
        if (Level.active) return "level";
        if (root._peeking) return "peek";
        return "rest";
    }

    readonly property bool resting: phase === "rest"
    readonly property bool voicing: phase === "listening" || phase === "thinking"
    readonly property bool levelling: phase === "level"
    readonly property bool peeking: phase === "peek"
    readonly property bool showingPanel: phase === "open"
    readonly property bool launching: phase === "launch"

    readonly property alias shape: shape
    readonly property alias alertShape: alertShape

    // Dikteringen lukker en aaben menu. Man skal ikke sidde med en liste
    // aabenstaaende og tale ud i den.
    onVoicingChanged: if (voicing) {
        Pill.close();
        Launcher.close();
    }

    function close(): void {
        if (Launcher.active) Launcher.close(); else Pill.back();
    }

    Timer {
        id: peekDelay
        interval: Config.peekDelay
        repeat: false
        onTriggered: Pill.peeking = true
    }

    // Hyprland fortaeller naar der klikkes udenfor. Uden det ville en aaben
    // menu ikke kunne lukkes med musen -- masken goer at klik udenfor pillen
    // slet ikke naar frem til os.
    // Aabneren beder om tastaturet i samme oejeblik den kommer frem, og
    // Hyprland melder grebet "ryddet" med det samme hvis vinduet endnu ikke
    // har faaet det. Uden ventetiden lukkede aabneren sig selv i samme sekund
    // den blev aabnet.
    readonly property bool wantGrab: root.opened || Launcher.active
    property bool grabReady: false

    onWantGrabChanged: {
        root.grabReady = false;
        if (root.wantGrab) grabArm.restart(); else grabArm.stop();
    }

    Timer {
        id: grabArm
        interval: Config.grabDelay
        repeat: false
        onTriggered: root.grabReady = true
    }

    HyprlandFocusGrab {
        active: root.wantGrab && root.grabReady
        windows: [root.hostWindow]
        onCleared: {
            Pill.close();
            Launcher.close();
        }
    }

    // ---- afvigelses-pillen ------------------------------------------------
    // Den lille pille ved siden af kroppen. Her staar det der afviger -- og
    // her kommer beskederne ind. Baade boblen og listen: klikker han paa
    // "N beskeder", folder listen sig ud i den her form. Den aabner ikke
    // kroppen, for saa ville det maskinen siger, skubbe det han selv laver.
    //
    // Beskeder laa foerst i kroppen, men kroppen er det Filip *goer*: stemmen,
    // menuen, aabneren. En besked er noget der sker for ham, ikke noget han er
    // i gang med, og den maa ikke skubbe det han laver til side. Derfor har
    // den sin egen form -- den samme som "laast" og "koffein" bor i.
    Rectangle {
        id: alertShape

        anchors.right: shape.left
        anchors.rightMargin: Config.bodyMargin
        anchors.bottom: shape.bottom

        // Root-adgang vinder over en besked: den venter paa ham, og den er
        // kortvarig. En besked kan komme igen, det kan et spoergsmaal ikke.
        //
        // Gotcha: linjen er ogsaa det eneste sted Sudo bliver naevnt fra noget
        // der selv bliver bygget -- og en singleton ingen naevner, bygger
        // Quickshell aldrig. Fjernes den, findes IPC-indgangen `sudo` ikke.
        readonly property bool asking: Sudo.showing
        // Listen vinder over boblen: den staar aaben fordi han bad om det, og
        // en ny besked er allerede med i den.
        readonly property bool listing: !alertShape.asking && Notifs.listing
        readonly property bool noting:
            !alertShape.asking && !alertShape.listing && Notifs.popup
        readonly property bool wide:
            alertShape.asking || alertShape.listing || alertShape.noting
        // Tale vokser, men kun lidt, og den taber til baade root-adgang og en
        // besked: de venter paa ham, tale gaar over af sig selv.
        readonly property bool talking: !alertShape.wide && Tale.talking

        width: {
            if (alertShape.wide)
                return Config.notifyWidth + 2 * Config.activePadding;
            if (!alerts.any) return 0;
            return alerts.implicitWidth
                + 2 * (alertShape.talking ? Config.talePadding : Config.restPadding);
        }
        height: {
            if (alertShape.asking) return sudo.implicitHeight + 2 * Config.activePadding;
            if (alertShape.listing) return liste.implicitHeight + 2 * Config.activePadding;
            if (alertShape.noting) return notify.implicitHeight + 2 * Config.activePadding;
            return alertShape.talking ? Config.taleHeight : Config.restHeight;
        }
        radius: Math.min(height / 2, Config.bodyMaxRadius)
        visible: width > 0

        color: Theme.barBackground
        border.width: Config.borderWidth
        // Grundfarven er vinduernes egen kant. Kun det der afviger, faar en
        // anden -- ellers betyder farve ingenting.
        border.color: {
            if (alertShape.asking)
                return Sudo.accepted ? Theme.stateGood : Theme.stateBad;
            if (alertShape.noting)
                return Notifs.critical ? Theme.stateBad : Theme.color5;
            if (alertShape.listing) return Theme.color5;
            return Theme.windowBorder;
        }
        clip: true

        Behavior on width {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: Config.morphDuration }
        }

        // Midt i formen. Uden det saetter indholdet sig oppe i venstre
        // hjoerne og ser ud til at ligge uden for pillen.
        Alerts {
            id: alerts
            anchors.centerIn: parent
            opacity: alertShape.wide ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        NotifyList {
            id: liste
            anchors.centerIn: parent
            opacity: alertShape.listing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        NotifyContent {
            id: notify
            anchors.centerIn: parent
            opacity: alertShape.noting ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        SudoContent {
            id: sudo
            anchors.centerIn: parent
            opacity: alertShape.asking ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }
    }

    // ---- kroppen ----------------------------------------------------------
    Rectangle {
        id: shape

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.bodyMargin
        anchors.right: Config.bodyAlign === "right" ? parent.right : undefined
        anchors.rightMargin: Config.bodyMargin
        anchors.left: Config.bodyAlign === "left" ? parent.left : undefined
        anchors.leftMargin: Config.bodyMargin
        anchors.horizontalCenter:
            Config.bodyAlign === "center" ? parent.horizontalCenter : undefined
        anchors.horizontalCenterOffset:
            alertShape.width > 0 ? (alertShape.width + Config.bodyMargin) / 2 : 0
        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }

        width: {
            if (root.voicing) return Config.bodyVoiceWidth;
            if (root.launching) return Config.launchWidth + 2 * Config.activePadding;
            if (root.showingPanel) return Config.openWidth + 2 * Config.activePadding;
            if (root.levelling) return level.implicitWidth + 2 * Config.activePadding;
            if (root.peeking) return peek.implicitWidth + 2 * Config.activePadding;
            return rest.implicitWidth + 2 * Config.restPadding;
        }
        height: {
            // Uret og batteriet bliver liggende naar kroppen bliver til en
            // boelge -- den vokser opad og lader linjen staa hvor den stod.
            if (root.voicing) return Config.bodyVoiceHeight + Config.restHeight;
            if (root.launching) return launch.implicitHeight + 2 * Config.activePadding;
            if (root.showingPanel) return panel.implicitHeight + 2 * Config.activePadding;
            // Kigget stabler sine linjer lodret som menuen, saa det er
            // indholdet der bestemmer hoejden. Niveauet er stadig én linje.
            if (root.peeking) return peek.implicitHeight + 2 * Config.activePadding;
            if (root.levelling) return Config.activeHeight;
            return Config.restHeight;
        }
        // Vokser den op til en menu, holder hjoernerne op med at vaere en
        // pille -- en hoej form med halvcirkler i enderne ser forkert ud.
        radius: Math.min(height / 2, Config.bodyMaxRadius)

        color: Theme.barBackground
        border.width: Config.borderWidth
        // Samme kant som vinduerne har, undtagen naar der bliver dikteret --
        // der skifter hele formen alligevel, og farven foelger stemmen.
        //
        // Aabneren og menuen havde foer deres egen kantfarve. Den var color4,
        // og det er nu grundfarven, saa den sagde ikke laengere noget: formen
        // er allerede vokset til en liste.
        border.color: {
            if (root.voicing) return Voice.color;
            return Theme.windowBorder;
        }
        clip: true

        Behavior on width {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: Config.morphDuration }
        }

        // Musen paa selve formen: rul skruer for lyden, klik aabner og lukker,
        // og bliver den haengende, kigger pillen ud. Ligger under indholdet, saa
        // raekkerne i menuen faar klikket foerst.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            z: -1

            enabled: !root.launching
            onEntered: if (!root.opened) peekDelay.restart()
            onExited: {
                peekDelay.stop();
                Pill.peeking = false;
            }
            onClicked: Pill.toggle()
            onWheel: event => {
                Audio.nudge(event.angleDelta.y > 0 ? 5 : -5);
                event.accepted = true;
            }
        }

        // Uret og batteriet forsvandt foer, i det oejeblik han begyndte at
        // tale. Det er de to ting han kigger paa uden at taenke over det, og
        // dikteringen er ikke en grund til at holde dem skjult. De bliver
        // liggende praecis hvor de laa -- kroppen folder sig ud opad omkring
        // dem i stedet for at skubbe dem ud.
        RestContent {
            id: rest
            //
            // ÉT anker, ikke to der skiftes imellem: linjen haenger fast i
            // bunden med praecis den luft der centrerer den i en pille i
            // hvile. Saa ligger den samme sted i begge tilstande af sig selv.
            // (To ankre der byttes strides -- bunden og midten kan ikke begge
            // gaelde, og saa satte den sig i toppen.)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (Config.restHeight - rest.implicitHeight) / 2
            bodyScreen: root.bodyScreen
            opacity: (root.resting || root.voicing) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        PeekContent {
            id: peek
            anchors.centerIn: parent
            opacity: root.peeking ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        LevelContent {
            id: level
            anchors.centerIn: parent
            opacity: root.levelling ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        LaunchContent {
            id: launch
            anchors.centerIn: parent
            opacity: root.launching ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        OpenPanel {
            id: panel
            anchors.centerIn: parent
            opacity: root.showingPanel ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        Item {
            anchors.fill: parent
            anchors.margins: Config.voicePadding
            // Plads til hvilelinjen nedenunder, plus den samme luft som over
            // boelgen. Saa beholder boelgen selv den hoejde den havde.
            anchors.bottomMargin: Config.restHeight + Config.voicePadding
            opacity: root.voicing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }

            // Ingen tekst. Formen og farven siger det: pillen er blevet en
            // anden, og boelgen bevaeger sig efter stemmen. Ordet "lytter"
            // fortalte kun hvad man i forvejen kunne se.
            Waveform {
                anchors.fill: parent
                level: Voice.level
                breathing: Voice.thinking
                colorLeft: Voice.color
                colorRight: Voice.listening ? Theme.color6 : Voice.color
            }
        }
    }
}

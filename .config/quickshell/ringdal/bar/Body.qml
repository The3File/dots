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
    //
    // MED ÉN UNDTAGELSE: staar der et frit felt, er det netop DÉR de talte ord
    // skal hen. Reglen blev skrevet foer feltet fandtes, og den slog den frie
    // linje ihjel -- Filip trykkede paa dikteringen, menuen lukkede, og naar
    // teksten var faerdig, var der ikke noget felt at lande i. Saa spurgte
    // hyprwhspr `pill felt`, fik "nej", og linjen endte i udklip i stedet
    // (fanget 30-08 i loggen: "Vindue ikke fundet -- teksten lagt i udklip").
    //
    // Et KODE-felt taeller ikke: en adgangskode dikteres ikke, og saa gaelder
    // den oprindelige regel igen.
    //
    // Kroppen morfer alligevel til boelgen imens -- én krop, én form ad
    // gangen -- og folder sig tilbage til feltet med ordene i, naar han er
    // faerdig med at tale.
    onVoicingChanged: if (voicing) {
        if (Menu.prompt !== null && !(Menu.prompt.masked ?? true)) return;
        Pill.close();
        Launcher.close();
    }

    // Escape. Rangordenen er den samme som resten af pillen bygger paa:
    // aabneren foerst, saa menuen, og til sidst beskedlisten -- input foer
    // output. Menuen afgoer selv om escape betyder ét lag tilbage eller helt
    // ud; se Menu.entry.
    function esc(): void {
        if (Launcher.active) { Launcher.close(); return; }
        if (Pill.opened) { Pill.esc(); return; }
        if (Agent.showing) { Agent.hide(); return; }
        if (Notifs.listing) Notifs.closeList();
    }

    Timer {
        id: peekDelay
        interval: Config.peekDelay
        repeat: false
        onTriggered: Pill.peeking = true
    }

    // Hyprland fortaeller naar der klikkes udenfor. Uden det ville en aaben
    // menu ikke kunne lukkes med musen -- masken goer at klik udenfor pillen
    // slet ikke naar frem til os, og at klikke sig ud er den foerste ting man
    // proever.
    //
    // Grebet tager ogsaa tastaturet, saa laget behoever ikke bede om det med
    // Exclusive -- og maa ikke: Exclusive laaser tastaturet fast paa laget, og
    // saa rydder Hyprland aldrig grebet. Se kommentaren i Bar.qml.
    //
    // Der laa foer en ventetid (grabDelay) foran, fordi Hyprland meldte grebet
    // ryddet med det samme, naar vinduet endnu ikke havde faaet tastaturet.
    // Den er vaek sammen med Exclusive: nu er det grebet selv der giver
    // tastaturet, saa der er ikke noget at vente paa -- og ventetiden var
    // dyr, for i de millisekunder gik hans foerste tastetryk til vinduet
    // bagved i stedet for ned i aabneren.
    // Beskedlisten er med i grebet (29-08). Den bor i output-pillen og har
    // ingen tastaturfokus, men den staar aaben fordi han selv foldede den ud
    // -- og saa skal den kunne lukkes paa den samme maade som menuen: ved at
    // klikke et andet sted. Uden grebet naar det klik aldrig frem, fordi
    // masken lader alt uden for pillerne falde igennem.
    //
    // Boblen og root-spoergsmaalet er IKKE med: de er noget maskinen rejser,
    // ikke noget han aabnede. Boblen gaar over af sig selv, og et spoergsmaal
    // skal besvares, ikke klikkes vaek ved et uheld.
    // Kigget paa Claude er med af samme grund som beskedlisten: han foldede
    // den selv ud, og saa skal et klik ved siden af kunne lukke den igen.
    readonly property bool wantGrab:
        root.opened || Launcher.active || Notifs.listing || Agent.showing

    HyprlandFocusGrab {
        active: root.wantGrab
        windows: [root.hostWindow]
        onCleared: {
            Pill.close();
            Launcher.close();
            Notifs.closeList();
            Agent.hide();
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

        // Output-pillen ligger paa den side af kroppen, der vender VAEK fra
        // skaermkanten -- ellers ville den vokse ud af skaermen, naar en
        // besked folder sig ud. Med kroppen i hoejre hjoerne betyder det til
        // venstre; staar `align` paa "left", vender det om. "center" beholder
        // venstre, for der er plads til begge sider, og kroppens
        // horizontalCenterOffset regner allerede med at parret ligger sådan.
        readonly property bool paaHoejre: Config.bodyAlign === "left"

        anchors.right: alertShape.paaHoejre ? undefined : shape.left
        anchors.rightMargin: Config.bodyMargin
        anchors.left: alertShape.paaHoejre ? shape.right : undefined
        anchors.leftMargin: Config.bodyMargin
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
        // Kigget paa Claude staar i samme raekke som beskedlisten: begge er
        // noget han selv foldede ud. De to kan ikke staa samtidig -- den ene
        // lukker den anden, se Notifs.openList og Agent.show.
        readonly property bool claude:
            !alertShape.asking && !alertShape.listing && Agent.showing
        readonly property bool noting:
            !alertShape.asking && !alertShape.listing && !alertShape.claude
            && Notifs.popup
        // Musen blev haengende paa output-pillen. Den folder sig en smule ud
        // og viser hvad der ligger -- passivt, som kroppens kig. "3 beskeder"
        // siger hvor mange, ikke hvad, og det eneste man kunne goere ved
        // tallet var at klikke og se efter.
        //
        // Kigget vinder over talestregerne: at holde musen dér er noget han
        // GOER, boelgen ligger bare og koerer. Den linje der laeses op, kan
        // stadig springes over med Super+Escape.
        readonly property bool peeking:
            !alertShape.asking && !alertShape.listing && !alertShape.noting
            && !alertShape.claude && alertHover.hovered && Notifs.count > 0
        readonly property bool wide:
            alertShape.asking || alertShape.listing || alertShape.noting
            || alertShape.claude || alertShape.peeking
        // Tale vokser, men kun lidt, og den taber til baade root-adgang og en
        // besked: de venter paa ham, tale gaar over af sig selv.
        readonly property bool talking: !alertShape.wide && Tale.talking

        width: {
            if (alertShape.peeking)
                return Config.notifyPeekWidth + 2 * Config.activePadding;
            if (alertShape.wide)
                return Config.notifyWidth + 2 * Config.activePadding;
            if (!alerts.any) return 0;
            return alerts.implicitWidth
                + 2 * (alertShape.talking ? Config.talePadding : Config.restPadding);
        }
        height: {
            if (alertShape.asking) return sudo.implicitHeight + 2 * Config.activePadding;
            if (alertShape.listing) return liste.implicitHeight + 2 * Config.activePadding;
            if (alertShape.claude) return claude.implicitHeight + 2 * Config.activePadding;
            if (alertShape.noting) return notify.implicitHeight + 2 * Config.activePadding;
            if (alertShape.peeking) return kig.implicitHeight + 2 * Config.activePadding;
            return alertShape.talking ? Config.taleHeight : Config.restHeight;
        }
        radius: Math.min(height / 2, Config.bodyMaxRadius)
        visible: width > 0

        color: Theme.barBackground
        border.width: Config.borderWidth
        // Kun det der afviger, faar en anden farve end grundkanten -- ellers
        // betyder farve ingenting.
        border.color: {
            if (alertShape.asking)
                return Sudo.accepted ? Theme.stateGood : Theme.stateBad;
            if (alertShape.noting)
                return Notifs.critical ? Theme.stateBad : Theme.color5;
            if (alertShape.listing) return Theme.color5;
            // Kanten laaner prikkens farve: venter den paa ham, er den roed
            // ogsaa naar fladen er foldet ud og prikken selv er skjult bag den.
            if (alertShape.claude) return Agent.color;
            return Theme.pillBorder;
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

        // Hover paa HELE output-pillen. HoverHandler og ikke en MouseArea:
        // indholdet har sine egne museflader (boelgen, den aabne besked), og
        // en MouseArea ovenover ville tage deres hover fra dem.
        HoverHandler { id: alertHover }

        // Klik paa formen, dér hvor indholdet ikke selv tager det: folder
        // listen ud, eller lukker den igen. Ligger under indholdet, saa
        // boelgen stadig faar sit eget klik (spring linjen over).
        //
        // Slaaet fra mens der spoerges om root-adgang eller mens listen staar
        // aaben: dér har fladen sine egne linjer at ramme, og et klik i
        // luften omkring dem maa ikke betyde noget andet.
        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: !alertShape.asking && !alertShape.listing && !alertShape.claude
            onClicked: Notifs.openList()
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

        NotifyPeek {
            id: kig
            anchors.centerIn: parent
            opacity: alertShape.peeking ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Config.morphDuration / 2 } }
        }

        ClaudeContent {
            id: claude
            anchors.centerIn: parent
            opacity: alertShape.claude ? 1 : 0
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
        // Grundkanten, undtagen naar der bliver dikteret -- der skifter hele
        // formen alligevel, og farven foelger stemmen.
        //
        // Aabneren og menuen havde foer deres egen kantfarve (color4). Den er
        // vaek: formen er allerede vokset til en liste, saa farven sagde det
        // samme én gang til.
        border.color: {
            if (root.voicing) return Voice.color;
            return Theme.pillBorder;
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

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
//   besked   noget kom ind. Kort, og traekker sig selv -- undtagen kritiske.
//   niveau   du skruede paa lyd eller lys. Kort, og kun bredere.
//   kig      musen blev haengende. Passiv -- viser mere, goer intet.
//   hvile    klokken og batteriet.
//
// Beskeden ligger under den aabne menu med vilje: er du i gang med at vaelge
// et netvaerk, skal listen ikke forsvinde under haanden paa dig. Beskeden
// bliver i listen imens og kommer frem naar du er faerdig.
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
        if (Notifs.popup) return "notify";
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
    readonly property bool notifying: phase === "notify"

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
    Rectangle {
        id: alertShape

        anchors.right: shape.left
        anchors.rightMargin: Config.bodyMargin
        anchors.bottom: shape.bottom

        width: alerts.any ? alerts.implicitWidth + 2 * Config.restPadding : 0
        height: Config.restHeight
        radius: Math.min(height / 2, Config.bodyMaxRadius)
        visible: width > 0

        color: Theme.barBackground
        border.width: 1
        border.color: Theme.color8
        clip: true

        Behavior on width {
            NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
        }

        // Midt i formen. Uden det saetter indholdet sig oppe i venstre
        // hjoerne og ser ud til at ligge uden for pillen.
        Alerts {
            id: alerts
            anchors.centerIn: parent
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
            if (root.notifying) return Config.notifyWidth + 2 * Config.activePadding;
            if (root.levelling) return level.implicitWidth + 2 * Config.activePadding;
            if (root.peeking) return peek.implicitWidth + 2 * Config.activePadding;
            return rest.implicitWidth + 2 * Config.restPadding;
        }
        height: {
            if (root.voicing) return Config.bodyVoiceHeight;
            if (root.launching) return launch.implicitHeight + 2 * Config.activePadding;
            if (root.showingPanel) return panel.implicitHeight + 2 * Config.activePadding;
            if (root.notifying) return notify.implicitHeight + 2 * Config.activePadding;
            if (root.levelling || root.peeking) return Config.activeHeight;
            return Config.restHeight;
        }
        // Vokser den op til en menu, holder hjoernerne op med at vaere en
        // pille -- en hoej form med halvcirkler i enderne ser forkert ud.
        radius: Math.min(height / 2, Config.bodyMaxRadius)

        color: Theme.barBackground
        border.width: 1
        border.color: {
            if (root.voicing) return Voice.color;
            if (root.notifying) return Notifs.critical ? Theme.stateBad : Theme.color5;
            if (root.launching || root.showingPanel) return Theme.color4;
            return Theme.color8;
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

        RestContent {
            id: rest
            anchors.centerIn: parent
            bodyScreen: root.bodyScreen
            opacity: root.resting ? 1 : 0
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

        NotifyContent {
            id: notify
            anchors.centerIn: parent
            opacity: root.notifying ? 1 : 0
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

pragma Singleton

import Quickshell
import Quickshell.Io
import qs.services

// Brugerens skruer, læst fra config.json ved siden af. watchChanges betyder at
// en rettelse i JSON-filen slår igennem med det samme — ingen genstart, ingen QML.
// Værdierne her i QML er defaults; JSON'en overskriver kun det den nævner.
Singleton {
    id: root

    readonly property var _bar: file.data.bar ?? ({})
    readonly property var _intervals: file.data.intervals ?? ({})
    readonly property var _font: _bar.font ?? ({})
    readonly property var _voice: file.data.voice ?? ({})

    readonly property int barHeight: _bar.height ?? 26
    // Tom liste = bar på alle skærme. Ellers fx ["eDP-1"].
    readonly property var barScreens: _bar.screens ?? []

    readonly property string fontFamily: _font.family ?? "Terminus"
    readonly property int fontSize: _font.size ?? 14

    readonly property int whsprInterval: _intervals.whspr ?? 1000
    readonly property int perfInterval: _intervals.perf ?? 2000
    readonly property int keylockInterval: _intervals.keylock ?? 5000
    readonly property int netInterval: _intervals.net ?? 5000
    readonly property int backlightInterval: _intervals.backlight ?? 5000
    readonly property int koffeinInterval: _intervals.koffein ?? 30000
    readonly property int clockInterval: _intervals.clock ?? 30000

    // ---- stemmefladen ----------------------------------------------------
    // Motoren skriver audio_level hvert 100 ms. Hurtigere aflaesning giver
    // ikke nye tal -- kun mere forbrug.
    readonly property int voiceLevelInterval: _voice.levelInterval ?? 100
    readonly property int voiceStateInterval: _voice.stateInterval ?? 250
    readonly property int voiceWidth: _voice.width ?? 320
    readonly property int voiceHeight: _voice.height ?? 52
    readonly property int voiceMarginLeft: _voice.marginLeft ?? 16
    readonly property int voiceMarginBottom: _voice.marginBottom ?? 50
    readonly property bool voiceEnabled: _voice.enabled ?? true

    // ---- kroppen ---------------------------------------------------------
    readonly property var _body: file.data.body ?? ({})
    // Luft ud til skaermkanten, saa de runde hjoerner har noget at vaere
    // runde imod.
    readonly property int bodyMargin: _body.margin ?? 8
    // Hvor hoej kroppen bliver naar den lytter.
    readonly property int bodyVoiceHeight: _body.voiceHeight ?? 60
    readonly property int bodyMaxRadius: _body.maxRadius ?? 20
    // Kanten om pillerne. Skal vaere den samme som `border_size` i
    // hyprland.lua -- en tyndere kant end vinduernes faar pillen til at ligne
    // noget der er lagt oven paa skaermen i stedet for noget der hoerer til.
    readonly property int borderWidth: _body.borderWidth ?? 2
    // Hvor meget af tapetets lyse tone kanten faar. 1 = tonen ren, 0 = den
    // forsvinder i pillen. Den findes, fordi "lys nok til at holde formen
    // sammen" og "ikke saa lys at den raaber" er en smagsting, der skal kunne
    // proeves af med det samme -- JSON'en laeses om mens pillen koerer.
    readonly property real borderTone: _body.borderTone ?? 0.7
    // Bredde naar kroppen lytter. 0 = behold fuld bredde.
    readonly property int bodyVoiceWidth: _body.voiceWidth ?? 240
    // Luft inde i pillerne, og mellem det de indeholder.
    readonly property int restPadding: _body.restPadding ?? 24
    // Alt andet end hvile faar mere luft end hvilen. Sker der noget, maa
    // formen godt aande -- hvilen er den der skal fylde mindst.
    readonly property int activePadding: _body.activePadding ?? 34
    // Mens der tales vokser output-pillen -- men kun lidt. Morfens stoerrelse
    // skal svare til begivenhedens: tale er ikke et spoergsmaal, det er noget
    // der gaar over af sig selv. Derfor mellem hvile og aktiv, ikke helt oppe.
    readonly property int talePadding: _body.talePadding ?? 29
    readonly property int taleHeight: _body.taleHeight ?? 40
    readonly property int activeHeight: _body.activeHeight ?? 42
    // Lyttetilstanden har sin egen, mindre luft: pillen er smal der, og
    // boelgen skal have plads frem for kanten.
    readonly property int voicePadding: _body.voicePadding ?? 16
    readonly property int restSpacing: _body.restSpacing ?? 20
    // Pillens egen hoejde i hvile. Staar for sig, saa luften indeni kan
    // aendres uden at flytte den plads der reserveres til vinduerne.
    readonly property int restHeight: _body.restHeight ?? 34
    // Hvor pillen ligger: "right", "center" eller "left".
    readonly property string bodyAlign: _body.align ?? "right"
    // Hvor laenge niveauet bliver staaende efter sidste aendring.
    readonly property int levelLinger: _body.levelLinger ?? 1600
    readonly property int levelWidth: _body.levelWidth ?? 210
    // Naadeperiode efter opstart, hvor niveau-aendringer ikke vises.
    readonly property int levelSettle: _body.levelSettle ?? 2000
    // Hvor laenge musen skal blive haengende foer pillen kigger ud. 0 = med
    // det samme. Forsinkelsen fandtes fordi pillen ligger i det hjoerne musen
    // kommer forbi -- men Filip vil hellere have at den svarer straks.
    readonly property int peekDelay: _body.peekDelay ?? 0
    // Kigget folder sig ud lodret, ikke sidelaens.
    readonly property int peekWidth: _body.peekWidth ?? 240
    readonly property int openWidth: _body.openWidth ?? 360
    // Hvor mange linjer menuen viser ad gangen. Fuzzel viste 12; her er der
    // faerre, fordi pillen ligger i et hjoerne og ikke midt paa skaermen.
    readonly property int menuLines: _body.menuLines ?? 10
    // Aabneren er bredere end menuen: der staar navn og hvad det er, og
    // programnavne er lange. Antal linjer er der hvor listen holder op med
    // at hjaelpe -- er det du soeger ikke i de foerste otte, skriver du et
    // bogstav mere i stedet for at kigge listen igennem.
    readonly property int launchWidth: _body.launchWidth ?? 420
    readonly property int launchLines: _body.launchLines ?? 8
    // Beskeder: bredden paa boblen, hvor laenge den bliver staaende, og hvor
    // mange der gemmes foer de aeldste ryger.
    readonly property int notifyWidth: _body.notifyWidth ?? 340
    readonly property int notifyLinger: _body.notifyLinger ?? 6000
    readonly property int notifyMax: _body.notifyMax ?? 20
    // Hvor mange linjer listen viser ad gangen. Faerre end menuen: den ligger i
    // output-pillen, og en historik man skal rulle i, er ikke laengere et
    // overblik.
    readonly property int notifyLines: _body.notifyLines ?? 6
    // Hvor laenge der ventes foer grebet om musen tages paa aabneren. Se
    // Body.qml -- Hyprland melder grebet ryddet med det samme, hvis vinduet
    // ikke har faaet tastaturet endnu.
    readonly property int grabDelay: _body.grabDelay ?? 200
    // Hvor laenge der maa gaa uden livstegn foer prikken holder op med at
    // aande. Jeg siger noget ved hvert faseskift, saa der er langt imellem.
    readonly property int agentStale: _body.agentStale ?? 240000
    // Samme slags vagthund for talen. Kortere, fordi en enkelt talt linje er
    // kort: gaar der saa lang tid uden et nyt push, er afspilleren doed.
    readonly property int taleStale: _body.taleStale ?? 90000
    // Hvor laenge "godkendt" bliver staaende, naar fingeraftrykket gik igennem.
    // Det skal kunne naas med oejnene, ogsaa naar man ikke sad og kiggede paa
    // pillen i forvejen -- man laegger fingeren og ser op bagefter.
    readonly property int sudoKvittering: _body.sudoKvittering ?? 1800
    // Hoejden paa den gennemsigtige flade pillen tegnes paa.
    readonly property int overlayHeight: _body.overlayHeight ?? 640
    // Alle formskift bruger den samme varighed. Ét tal, ét formsprog.
    readonly property int morphDuration: _body.morphDuration ?? 320
    // Hvor laenge arbejdsrum-tallet bliver staaende efter et skift.
    readonly property int workspaceLinger: _body.workspaceLinger ?? 1200

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: `${home}/.Scripts`

    function wantsScreen(screen): bool {
        return barScreens.length === 0 || barScreens.indexOf(screen.name) >= 0;
    }

    JsonFile {
        id: file
        file: `${Quickshell.env("HOME")}/.config/quickshell/ringdal/config.json`
        // Den her rettes i haanden, saa den maa gerne tjekkes lidt oftere.
        interval: 2000
    }

    IpcHandler {
        target: "config"
        function reload(): void { file.reload(); }
    }
}

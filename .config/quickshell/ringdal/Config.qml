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
    // ÉN skrue. Alt herunder er ganget paa den her -- luft, hoejder og
    // bredder. Ret den i config.json, og formen foelger med.
    //
    // Bemaerk: PIXELS. Alacrittys `size` er punkter, saa terminalens 14 er
    // 18 her (`fc-match -v "Terminus:size=14:dpi=96"`). Terminus er en
    // bitmap-skrift og findes kun i faste trin: 12/14/16/18/20/22/24/28/32.
    readonly property int fontSize: _font.size ?? 18

    // ---- luften foelger skriften -----------------------------------------
    // Alt det her var faste pixeltal, tunet til 14 px skrift. Da skriften
    // sprang til 18, klemte formen om teksten, og hver eneste skrue skulle
    // saettes i haanden bagefter. Nu er de forhold i stedet for tal, og
    // faktorerne er praecis de forhold formen HAVDE, da den saa rigtig ud.
    //
    // Vil du stadig laase én af dem, saa naevn den i config.json -- et
    // navngivet tal vinder som altid over det udregnede.
    function _em(f: real): int { return Math.round(root.fontSize * f); }

    // Terminus er lige bred: 10 px pr. tegn ved 18 px, 8 ved 14. Bredder
    // maales derfor i TEGN og ikke i pixels, saa en linje bliver ved med at
    // kunne holde det samme antal bogstaver, uanset skriftens stoerrelse.
    readonly property int cellWidth: Math.round(root.fontSize * 5 / 9)
    function _cols(n: int): int { return n * root.cellWidth; }

    readonly property int whsprInterval: _intervals.whspr ?? 1000
    // 0 = intet poll. Ydelsen og lysstyrken hentes, naar den flade der viser
    // dem folder sig ud (se Perf.qml og Backlight.qml). Saet et tal ind igen,
    // hvis de nogensinde skal staa fremme hele tiden.
    readonly property int perfInterval: _intervals.perf ?? 0
    // Bruges kun mens tastaturet ER laast -- ellers ser Keylock paa flagfilen.
    readonly property int keylockInterval: _intervals.keylock ?? 5000
    readonly property int netInterval: _intervals.net ?? 15000
    readonly property int backlightInterval: _intervals.backlight ?? 0
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
    readonly property int bodyVoiceHeight: _body.voiceHeight ?? _em(4.28)
    readonly property int bodyMaxRadius: _body.maxRadius ?? _em(1.44)
    // Kanten om pillerne. Vinduerne har 2 (border_size i hyprland.lua); pillen
    // har 1 med vilje -- den er lille og ligger i et hjoerne, og 2 px hele
    // vejen rundt om en lav form blev en streg man kiggede paa i stedet for
    // igennem.
    readonly property int borderWidth: _body.borderWidth ?? 1
    // Hvor meget af tapetets lyse tone kanten faar. 1 = tonen ren, 0 = den
    // forsvinder i pillen. Den findes, fordi "lys nok til at holde formen
    // sammen" og "ikke saa lys at den raaber" er en smagsting, der skal kunne
    // proeves af med det samme -- JSON'en laeses om mens pillen koerer.
    readonly property real borderTone: _body.borderTone ?? 0.7
    // Hvor taet pillen er. 1 = helt solid, 0 = usynlig. Sloeringen bagved er
    // ikke herfra -- den er en layer_rule paa namespace quickshell i
    // ~/.config/hypr/hyprland.lua, og dens ignore_alpha skal blive ved med at
    // ligge UNDER det her tal, ellers holder sloeringen op med at gaelde
    // pillen. Den staar paa 0.2, saa der er plads at skrue paa.
    readonly property real bodyOpacity: _body.opacity ?? 0.75
    // Bredde naar kroppen lytter. 0 = behold fuld bredde.
    readonly property int bodyVoiceWidth: _body.voiceWidth ?? _cols(30)
    // Luft inde i pillerne, og mellem det de indeholder.
    readonly property int restPadding: _body.restPadding ?? _em(1.72)
    // Alt andet end hvile faar mere luft end hvilen. Sker der noget, maa
    // formen godt aande -- hvilen er den der skal fylde mindst.
    readonly property int activePadding: _body.activePadding ?? _em(2.44)
    // Mens der tales vokser output-pillen -- men kun lidt. Morfens stoerrelse
    // skal svare til begivenhedens: tale er ikke et spoergsmaal, det er noget
    // der gaar over af sig selv. Derfor mellem hvile og aktiv, ikke helt oppe.
    readonly property int talePadding: _body.talePadding ?? _em(2.06)
    readonly property int taleHeight: _body.taleHeight ?? _em(2.83)
    readonly property int activeHeight: _body.activeHeight ?? _em(3)
    // Lyttetilstanden har sin egen, mindre luft: pillen er smal der, og
    // boelgen skal have plads frem for kanten.
    readonly property int voicePadding: _body.voicePadding ?? _em(1.17)
    readonly property int restSpacing: _body.restSpacing ?? _em(1.44)
    // Pillens egen hoejde i hvile. Staar for sig, saa luften indeni kan
    // aendres uden at flytte den plads der reserveres til vinduerne.
    readonly property int restHeight: _body.restHeight ?? _em(2.44)
    // Hvor pillen ligger: "right", "center" eller "left".
    readonly property string bodyAlign: _body.align ?? "right"
    // Hvor laenge niveauet bliver staaende efter sidste aendring.
    readonly property int levelLinger: _body.levelLinger ?? 1600
    readonly property int levelWidth: _body.levelWidth ?? _cols(26)
    // Naadeperiode efter opstart, hvor niveau-aendringer ikke vises.
    readonly property int levelSettle: _body.levelSettle ?? 2000
    // Hvor laenge musen skal blive haengende foer pillen kigger ud. 0 = med
    // det samme. Forsinkelsen fandtes fordi pillen ligger i det hjoerne musen
    // kommer forbi -- men Filip vil hellere have at den svarer straks.
    readonly property int peekDelay: _body.peekDelay ?? 0
    // Kigget folder sig ud lodret, ikke sidelaens.
    readonly property int peekWidth: _body.peekWidth ?? _cols(30)
    readonly property int openWidth: _body.openWidth ?? _cols(45)
    // Hvor mange linjer menuen viser ad gangen. Fuzzel viste 12; her er der
    // faerre, fordi pillen ligger i et hjoerne og ikke midt paa skaermen.
    readonly property int menuLines: _body.menuLines ?? 10
    // Aabneren er bredere end menuen: der staar navn og hvad det er, og
    // programnavne er lange. Antal linjer er der hvor listen holder op med
    // at hjaelpe -- er det du soeger ikke i de foerste otte, skriver du et
    // bogstav mere i stedet for at kigge listen igennem.
    readonly property int launchWidth: _body.launchWidth ?? _cols(52)
    readonly property int launchLines: _body.launchLines ?? 8
    // Beskeder: bredden paa boblen, hvor laenge den bliver staaende, og hvor
    // mange der gemmes foer de aeldste ryger.
    readonly property int notifyWidth: _body.notifyWidth ?? _cols(42)
    readonly property int notifyLinger: _body.notifyLinger ?? 6000
    readonly property int notifyMax: _body.notifyMax ?? 20
    // Hvor mange linjer listen viser ad gangen. Faerre end menuen: den ligger i
    // output-pillen, og en historik man skal rulle i, er ikke laengere et
    // overblik.
    readonly property int notifyLines: _body.notifyLines ?? 6
    // Kigget paa output-pillen: smallere og kortere end listen. Det er et kig,
    // ikke en historik -- er der mere, staar der "+N mere", og saa klikker han.
    readonly property int notifyPeekWidth: _body.notifyPeekWidth ?? _cols(37)
    readonly property int notifyPeekLines: _body.notifyPeekLines ?? 3
    // Hvor laenge der maa gaa uden livstegn foer prikken holder op med at
    // aande. Jeg siger noget ved hvert faseskift, saa der er langt imellem.
    readonly property int agentStale: _body.agentStale ?? 240000
    // Hvor mange overskrifter kigget paa Claude viser, og hvor tit det
    // opfriskes mens det staar aabent. Faa linjer med vilje: fladen svarer paa
    // "hvad laver den, og haenger den?" -- resten staar i terminalen, ét
    // tastetryk vaek. Opfriskningen koerer KUN mens fladen er synlig.
    readonly property int agentLines: _body.agentLines ?? 3
    readonly property int agentRefresh: _body.agentRefresh ?? 3000
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

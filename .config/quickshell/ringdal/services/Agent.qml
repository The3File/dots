pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Agentfladen. Kun ét spørgsmål: kører der noget, og skal du gribe ind?
//
// Første udgave viste også den seneste talte linje i kroppen. Det var forkert
// to gange. Kroppen er INPUT -- det Filip putter ind i maskinen: stemmen,
// menuen, åbneren. Det her er output, og output hører til i pillen ved siden
// af. Og linjerne var skrevet til øret: en talt sætning er lavet til at
// passere, ikke til at blive stående og læses.
//
// Så ordene går gennem beskedfladen (den bobler op og trækker sig, og har en
// liste bagefter), og det eneste der bliver tilbage her er en prik.
//
// Prikken er ikke pynt. Den er svaret på det spørgsmål der før krævede
// konstant snak: er der stadig liv? Uden den var stilhed tvetydig, og derfor
// stod der "stilhed er fejlen" i tale. Med den kan stemmen tie.
//
// ---------------------------------------------------------------------------
// TO KILDER, OG DEN ENE VED BESKED (30-08-2026)
//
// Prikken blev før FORTALT af Claude gennem hooks: `__tur` sagde arbejder,
// `__puls` sagde arbejder igen ved hvert eneste værktøjskald, `__net` sagde
// færdig. Alt derimellem -- et svar på et spørgsmål, en godkendt tilladelse,
// en session der døde uden at sige farvel -- gik udenom, og så stod prikken
// forkert. Derfor var der bygget en stale-timer oven på til at gætte resten.
//
// herdr EJER de terminaler sessionerne kører i og SER tilstanden selv. Den er
// nu den primære kilde (`tale __foelg`, én linje pr. skift, i git). IPC'en
// bliver stående som RESERVE for det ene tilfælde herdr ikke dækker: claude
// startet i et helt almindeligt vindue uden for herdr. Og stale-gætteriet
// hører kun til dér -- ser herdr sessionen, gættes der ikke.
Singleton {
    id: root

    property string state: "ledig"
    // Hvornår der sidst kom livstegn. Kun reservevejen har brug for det: uden
    // det kan pillen stå og sige "arbejder" i timevis, fordi en session døde
    // uden at sige farvel.
    property double lastSeen: 0

    // Sandt så længe herdr ser en claude-session. Så vinder herdr, og et
    // IPC-kald fra hookene rører ikke tilstanden -- de to ville ellers kunne
    // slås om prikken, og den der taber ville være den der ved besked.
    property bool herdrStyrer: false

    readonly property bool working: root.state === "arbejder"
    readonly property bool waiting: root.state === "venter"
    readonly property bool active: root.working || root.waiting

    // Tavs, men i live. Prikken holder op med at ånde og bliver grå --
    // "der er noget der ikke er lukket ned" er også information.
    //
    // Er sessionen derimod væk, forsvinder fladen helt. En lukket Claude Code
    // står ikke og venter på noget; den er ingenting.
    //
    // Kun på reservevejen. Kommer tilstanden fra herdr, er der ikke noget at
    // være i tvivl om: `vaek` betyder væk.
    property bool stale: false

    readonly property color color: root.waiting ? Theme.stateBad
        : (root.stale ? Theme.color8 : Theme.color6)

    function _touch(): void {
        root.lastSeen = Date.now();
        root.stale = false;
        staleTimer.restart();
    }

    // --- herdr: den primære kilde ------------------------------------------
    //
    // Processen står og blokerer i `herdr agent wait` og koster ingenting
    // imens (målt 30-08: 48 ms CPU på otte sekunders ventetid). Den må derfor
    // gerne køre døgnet rundt -- til forskel fra alt der poller eller bevæger
    // sig, som er den dyreste lektie i hele fladen.
    Process {
        id: foelg
        // `setpriv --pdeathsig TERM`: dør pillen, dør strømmen med.
        //
        // Uden den bliver `tale __foelg` hængende som forældreløs og blokerer
        // videre i `herdr agent wait` -- den bliver jo aldrig vækket igen, så
        // den opdager det aldrig selv. Der samlede sig én for hver genstart af
        // pillen, og en genstart er det normale her (en omskrevet singleton
        // slår ikke igennem på hot-reload). Fanget 30-08 ved at tælle dem.
        //
        // `tale` rydder selv op efter herdr-processen, når signalet kommer.
        command: ["setpriv", "--pdeathsig", "TERM", "--",
                  `${Config.home}/.local/bin/tale`, "__foelg"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                const t = String(line).trim();
                if (t === "") return;
                if (t === "vaek" || t === "væk") {
                    // herdr ser ingen session. Så er det ikke herdr der ved
                    // besked længere, og reservevejen overtager.
                    //
                    // Vi slukker IKKE prikken her -- kører claude i et
                    // almindeligt vindue uden for herdr, er den stadig i live.
                    // Men vi må heller ikke bare lade den stå: forsvandt en
                    // herdr-session, ville prikken ellers ånde videre for
                    // evigt. Så vi spørger reservevejen med det samme, og
                    // lader DEN afgøre om der er liv.
                    //
                    // `__foelg` skriver kun `vaek` ved selve skiftet, så det
                    // her er ét opslag pr. session der forsvinder -- ikke en
                    // strøm.
                    root.herdrStyrer = false;
                    if (!liveness.running) liveness.running = true;
                    return;
                }
                root.herdrStyrer = true;
                root.state = t;
                root.stale = false;
                root.lastSeen = Date.now();
                staleTimer.stop();
                liveness.running = false;
            }
        }

        // Dør den, prøver vi igen -- men aldrig hurtigere end spærren, så et
        // nedbrud i `tale` ikke bliver til en løkke der starter processer så
        // hurtigt maskinen kan.
        onExited: {
            root.herdrStyrer = false;
            genstart.restart();
        }
    }

    Timer {
        id: genstart
        interval: 5000
        repeat: false
        onTriggered: if (!foelg.running) foelg.running = true;
    }

    // --- reserven: hookenes egne meldinger ---------------------------------

    Timer {
        id: staleTimer
        interval: Config.agentStale
        repeat: false
        onTriggered: if (!root.herdrStyrer && !liveness.running) liveness.running = true
    }

    // Logikken bor i tale, ikke her: hvad der tæller som en levende session er
    // en systemting, og den slags skal kunne prøves fra en terminal.
    Process {
        id: liveness
        command: [`${Config.home}/.local/bin/tale`, "__lever"]
        onExited: (code, status) => {
            if (root.herdrStyrer) return;   // herdr nåede at svare imens
            if (code === 0) {
                // Lever, men siger ikke noget. Bliv stående, og spørg igen.
                root.stale = true;
                staleTimer.restart();
            } else {
                root.state = "ledig";
                root.stale = false;
            }
        }
    }

    IpcHandler {
        target: "agent"

        // Reserve-vejen. Ser herdr sessionen, er de her kald støj -- den ved
        // det i forvejen og bedre, og to kilder der skriver på skift ville
        // give en prik der blinker mellem to sandheder.
        function working(): void {
            if (root.herdrStyrer) return;
            root.state = "arbejder"; root._touch();
        }
        function waiting(): void {
            if (root.herdrStyrer) return;
            root.state = "venter"; root._touch();
        }
        function done(): void {
            if (root.herdrStyrer) return;
            root.state = "ledig";
            root.stale = false;
            staleTimer.stop();
            liveness.running = false;
        }
        function state(): string {
            const kilde = root.herdrStyrer ? "herdr" : "hooks";
            return root.stale ? `${root.state} (stille, ${kilde})` : `${root.state} (${kilde})`;
        }
    }
}

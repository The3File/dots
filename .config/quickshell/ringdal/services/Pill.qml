pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Pillens egen tilstand. Ligger i en service og ikke i formen, af to grunde:
// tilstanden skal vaere den samme paa alle skaerme, og den skal kunne styres
// udefra.
//
// Reglen for hele shellen: ingen flade uden en IPC-indgang. Kan Claude ikke
// kalde den, er den ikke faerdig. Det er ogsaa den vej tastebindene gaar --
// Super+Shift+W aabner pillen i stedet for at starte en vaelger.
//
// Selve menuens indhold ligger i Menu (motoren) og Pages (siderne). Her staar
// kun om pillen er aaben, og hvor man kommer ind.
Singleton {
    id: root

    property bool opened: false
    // Kigget saettes af musen og har ingen IPC: det giver ingen mening at
    // "kigge" udefra, for kigget handler netop om hvor musen er.
    property bool peeking: false

    // Lysstyrken staar kun i kigget, saa den hentes naar kigget folder sig ud
    // -- ikke hvert femte sekund doegnet rundt. Samme regel som ydelsen:
    // poll kun det, der er synligt.
    onPeekingChanged: if (root.peeking) Backlight.refresh();

    function open(): void {
        root.opened = true;
        root.peeking = false;
        Menu.open(Pages.rootPage());
    }

    function close(): void {
        root.opened = false;
        Menu.close();
    }

    function toggle(): void {
        if (root.opened) root.close(); else root.open();
    }

    // Gaa direkte ind i en af siderne. Tastebindene og afvigelses-pillen
    // bruger den her, saa Super+Shift+W lander samme sted som et klik.
    function enter(name: string): void {
        // Beskeder er output. De folder sig ud i pillen ved siden af kroppen,
        // saa vejen ind i dem aabner ikke menuen -- uanset om det er et klik,
        // et tastebind eller Claude der kalder.
        if (name === "notifs") { Notifs.openList(); return; }
        // Det samme gaelder kigget paa Claude: det er noget maskinen giver
        // ham, og det folder sig ud i pillen ved siden af kroppen.
        if (name === "kig") { Agent.show(); return; }
        // "claude" er ikke en side laengere -- det er den frie linje. Siden med
        // terminaltekst er vaek; hvad sessionen laver, staar i output-pillen.
        if (name === "claude") { root.linje(); return; }
        root.opened = true;
        root.peeking = false;
        if (name === "wifi") Menu.open2(Pages.rootPage(), Pages.wifiPage());
        else if (name === "bt") Menu.open2(Pages.rootPage(), Pages.btPage());
        else if (name === "lyd") Menu.open2(Pages.rootPage(), Pages.lydPage());
        else if (name === "udgang") Menu.open2(Pages.lydPage(), Pages.udgangPage());
        else if (name === "indgang") Menu.open2(Pages.lydPage(), Pages.indgangPage());
        else if (name === "udklip") Menu.open2(Pages.rootPage(), Pages.clipPage());
        else if (name === "ydelse") Menu.open2(Pages.rootPage(), Pages.perfPage());
        else if (name === "sluk") Menu.open2(Pages.rootPage(), Pages.slukPage());
        else Menu.open(Pages.rootPage());
    }

    function notifs(): bool { return Notifs.openList(); }

    // Den frie linje: ét tryk, og feltet står der.
    //
    // Det er hele pointen med trinnet -- at kunne sige noget til en kørende
    // session uden at give skærmen væk.
    //
    // Rodmenuen ligger bagved, så escape lander ét sted man kan bruge. Den var
    // før lagt bag "hvad laver den?"-siden; den side findes ikke længere, fordi
    // terminalens tekst hører i output-pillen og ikke i menuen.
    //
    // Rækkefølgen holder: Menu._enter() nulstiller feltet, men fill() rører
    // det ikke, så spørgsmålet overlever at siden bliver hentet bagefter.
    function linje(): void {
        root.opened = true;
        root.peeking = false;
        Menu.open(Pages.rootPage());
        Pages.spoergClaude();
        // Feltet ER det, han aabnede -- rodmenuen bagved er kun en flade at
        // lande paa. Derfor lukker escape hele pillen herfra, ligesom
        // Super+Shift+W og Super+Shift+B goer. Se Menu.promptEntry.
        Menu.promptEntry = true;
    }

    // En side der bliver rejst udefra, ikke navigeret til -- fx spoergsmaalet
    // om lov til at koere noget som root. Den faar ingen rod bagved: der er
    // ikke noget at gaa "tilbage" til, kun et
    // spoergsmaal der skal besvares eller forlades.
    function modal(page: var): void {
        root.opened = true;
        root.peeking = false;
        Menu.open(page);
    }

    // Ét lag tilbage. Er der ikke flere lag, lukker den.
    function back(): void {
        if (Menu.active) Menu.back(); else root.close();
    }

    // Escape. Gaar ét lag tilbage, hvis han selv er gaaet et lag laengere ind
    // end der hvor han kom ind -- ellers lukker den hele menuen. Se Menu.entry:
    // en genvej aabner én ting, og escape skal lukke den samme ting igen.
    function esc(): void {
        if (Menu.active) Menu.esc(); else root.close();
    }

    // Afbryd det, der koerer lige nu. Én tast, én mening -- HVAD der bliver
    // afbrudt, afgoeres af hvad der er i gang.
    //
    // Dikterer han, er det dikteringen: det er hans egen stemme paa vej ind,
    // og den kan ikke vente. Dikterer han ikke, er der kun oplaesningen at
    // afbryde, og saa springes den linje over, der laeses nu.
    //
    // De to kan aldrig staa i vejen for hinanden, fordi input altid vinder
    // over output -- samme rangorden som resten af pillen bygger paa.
    function afbryd(): string {
        if (Voice.listening || Voice.paused) {
            afbrydStemme.running = true;
            return "afbroed dikteringen";
        }
        if (!Tale.talking) return "der er ingenting at afbryde";
        Tale.skip();
        return "sprang linjen over";
    }

    Process {
        id: afbrydStemme
        command: ["hyprwhspr", "record", "cancel"]
    }

    // Menuen kan ogsaa lukke sig selv (sidste lag + escape). Saa foelger
    // pillen med, i stedet for at staa aaben og tom.
    Connections {
        target: Menu
        function onClosed(): void { root.opened = false; }
    }

    IpcHandler {
        target: "pill"
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function back(): void { root.back(); }
        function esc(): void { root.esc(); }
        function afbryd(): string { return root.afbryd(); }
        function wifi(): void { root.enter("wifi"); }
        function bluetooth(): void { root.enter("bt"); }
        function beskeder(): string {
            return root.notifs() ? "aabnede listen" : "ingen beskeder";
        }
        function lyd(): void { root.enter("lyd"); }
        function udgang(): void { root.enter("udgang"); }
        function indgang(): void { root.enter("indgang"); }
        function udklip(): void { root.enter("udklip"); }
        function ydelse(): void { root.enter("ydelse"); }
        function sluk(): void { root.enter("sluk"); }
        function claude(): void { root.linje(); }
        function linje(): void { root.linje(); }
        // Kigget: hvad laver sessionen lige nu. Folder sig ud i output-pillen.
        function kig(): string { return Agent.toggle() ? "foldede kigget ud" : "lukkede kigget"; }
        function hvad(): string {
            return Agent.lines.length > 0 ? Agent.lines.join("\n") : "ingenting at vise";
        }
        // Menuen udefra: se hvad der staar, og tryk paa en linje.
        // Den linje tastaturet staar paa, er markeret. Den betyder noget nu,
        // hvor menuen navigeres med j og k i stedet for at man staver til
        // det, man vil have -- ellers kan Claude se listen uden at kunne se,
        // hvad et tryk ville ramme.
        function items(): string {
            if (!Menu.active) return "menuen er lukket";
            const cur = Menu.current;
            return Menu.labels()
                .map(l => (cur && l === (cur.label ?? "") ? "› " : "  ") + l)
                .join("\n");
        }
        function pick(label: string): string {
            if (!Menu.active) return "menuen er lukket";
            return Menu.pick(label) ? `valgte: ${label}` : `fandt ikke: ${label}`;
        }
        // Skriv i feltet, naar der spoerges om noget -- en wifi-kode, en
        // adgangskode. Det var menuens sidste tilstand uden en vej udefra, og
        // saa var den ikke faerdig.
        // Staar der et felt, og maa der tales ind i det?
        //
        // Dikteringen spoerger her, foer den indsaetter. En adgangskode skal
        // IKKE kunne dikteres -- hverken teknisk (den er skjult, han kan ikke
        // se om den blev rigtig) eller i praksis (man siger ikke sin kode
        // hoejt). Derfor er svaret ikke "der er et felt", men "hvad slags".
        function felt(): string {
            if (Menu.prompt === null) return "nej";
            return (Menu.prompt.masked ?? true) ? "kode" : "fri";
        }

        // Dikteringen skriver i feltet -- og sender.
        //
        // Han trykkede foer retur selv, saa en talt linje med et forkert ord i
        // kunne rettes foerst. Det viste sig at vaere den forkerte handel: han
        // aabner feltet, siger én saetning og er faerdig, og saa var returen
        // et ekstra greb ved tastaturet i en flade, der findes netop for at
        // slippe for at kigge paa skaermen. Fortryder han, staar sessionen ét
        // tryk vaek (Super+A). En kode kan stadig ikke dikteres.
        //
        // Der sendes ved at bede fladen om det, ikke ved at give teksten med:
        // feltet kan have noget i forvejen -- baade tastet og fra en tidligere
        // omgang tale -- og det skal med.
        function udfyld(tekst: string): string {
            if (Menu.prompt === null) return "der spoerges ikke om noget";
            if (Menu.prompt.masked ?? true) return "feltet er en kode";
            Menu.fyld(tekst);
            Menu.send();
            return "sendt";
        }

        function skriv(tekst: string): string {
            if (Menu.prompt === null) return "der spoerges ikke om noget";
            Menu.answer(tekst);
            return "svaret";
        }

        function state(): string {
            if (!root.opened) return "closed";
            return Menu.title === "" ? "open" : Menu.title;
        }
    }
}

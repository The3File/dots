pragma Singleton

import QtQuick
import Quickshell
import qs

// Menuens motor. Kender ingenting til wifi eller bluetooth -- den holder bare
// styr paa hvor man er, hvad der staar paa listen, og hvad tastaturet peger paa.
//
// Det er den samme model fuzzel havde: en liste, et filter man skriver i, og
// piletaster. Grunden til at den er skilt ud er, at hver eneste flade i pillen
// saa opfoerer sig ens -- man skal ikke laere en ny maade at gaa tilbage paa,
// fordi man er i bluetooth i stedet for wifi.
//
// En side er { title, load } hvor load() henter og kalder fill(). Sider kan
// vaere langsomme (et scan tager sekunder), saa listen fyldes bagefter, ikke
// paa stedet.
Singleton {
    id: root

    property var stack: []
    property var items: []
    property string query: ""
    property int index: 0
    // Bliver sat mens noget koerer, saa fladen kan sige hvorfor den er tom.
    property string status: ""

    // Et svar der skal skrives, fx en wifi-adgangskode:
    // { title, masked, prefix, submit(text), skift, note }. Er den sat, viser
    // fladen et felt i stedet for en liste.
    //
    // `note` er den valgfrie kontekst OVER feltet -- hvad der sidst skete i
    // det, man svarer paa. En adgangskode har ingen; den frie linje til Claude
    // har sessionens seneste linjer, saa han kan se hvad han taler ind i.
    //
    // `prefix` er det der staar foran markoeren. Det stod foer haardt som
    // "kode " i fladen, fordi alt der blev spurgt om, var en adgangskode. Den
    // frie linje til Claude er ikke en kode, hverken i hvad den er eller i
    // hvordan den skal se ud, saa ordet foelger nu med spoergsmaalet.
    property var prompt: null

    // Hvor mange gange der er blevet SPURGT. Feltet toemmes paa den her og
    // ikke paa `prompt`, fordi et spoergsmaal kan skifte overskrift midt i --
    // den frie linje skriver hvilken session den peger paa, og han kan skifte
    // den, mens han skriver. Toemtes der paa `prompt`, ville hans halve
    // saetning forsvinde i samme oejeblik.
    property int spoergNr: 0

    readonly property bool active: root.stack.length > 0
    readonly property bool nested: root.stack.length > 1

    // Hvor dybt han KOM IND. Escape lukker hele menuen, naar han staar dér --
    // og gaar kun ét lag tilbage, hvis han selv er gaaet laengere ind bagefter.
    //
    // Uden det betoed Super+Shift+W to tryk for at komme ud igen: ét der
    // landede paa rodmenuen han aldrig havde bedt om, og ét mere for at lukke
    // den. En genvej aabner én ting; escape lukker den samme ting.
    //
    // Vejen tilbage findes stadig -- overskriften "‹ wifi" og venstrepil gaar
    // op i roden. Det er kun escape der har den anden mening.
    property int entry: 1

    // Det samme, ét lag hoejere oppe: kom han ind PAA selve spoergsmaalet.
    // Den frie linje (Super+Shift+A) aabner feltet med det samme, og rodmenuen
    // bagved er kun en flade at lande paa -- den har han ikke bedt om. Saa
    // lukker escape det hele, praecis som Super+Shift+W og Super+Shift+B gaar
    // helt ud. Et spoergsmaal han selv gik ind i (wifi-noeglen, raekken
    // "Claude" i menuen) lukker kun sig selv, for dér ER der noget bagved.
    //
    // Nulstilles i open(), open2() og ask(), saa den kun staar, hvor nogen
    // udtrykkeligt saetter den bagefter -- se Pill.linje().
    property bool promptEntry: false

    // Hvor markeringen stod i hvert lag, man er gaaet forbi. Gaar man tilbage
    // fra en undermenu, lander man paa den linje, man kom ind ad -- ikke i
    // toppen. At skulle finde "bluetooth" igen, hver gang man har kigget ind
    // og fortrudt, er den slags smaating der goer en flade traettende.
    //
    // Der gemmes NAVNET og ikke nummeret: listerne bygges forfra hver gang, og
    // et scan kan have byttet om paa raekkerne imens. Nummeret ville pege paa
    // en tilfaeldig linje; navnet peger paa den samme.
    property var marks: []
    // Navnet vi leder efter i den liste, der er paa vej ind.
    property string want: ""
    readonly property string title: root.active ? root.stack[root.stack.length - 1].title : ""

    readonly property var view: root._filter(root.items, root.query)
    readonly property var current:
        root.index >= 0 && root.index < root.view.length ? root.view[root.index] : null

    signal closed()

    // Tekst paa vej ind i feltet UDEFRA -- i praksis dikteringen. Den bliver
    // lagt i feltet, ikke sendt: en talt linje kan indeholde et forkert ord,
    // og han skal have lov at se den, foer den gaar videre. Det er ogsaa den
    // samme opfoersel som alle andre steder paa maskinen -- diktering saetter
    // tekst ind, den trykker ikke retur for én.
    signal filled(string text)

    // "Send det der staar i feltet nu." Teksten bor i fladen (OpenPanel) og
    // ikke her, saa der gaar et signal ud i stedet for et kald med tekst i --
    // ellers ville det, han selv havde skrevet foerst, falde paa gulvet.
    signal sender()

    function open(page: var): void {
        root.stack = [page];
        root.entry = 1;
        root.promptEntry = false;
        root.marks = [];
        root._enter();
    }

    // Aabn direkte paa et underlag, med roden bagved. Saa virker "tilbage"
    // ogsaa naar man kom ind udefra i stedet for gennem roden.
    function open2(base: var, page: var): void {
        root.stack = [base, page];
        root.entry = 2;
        root.promptEntry = false;
        root.marks = [];
        root._enter();
    }

    function push(page: var): void {
        const m = root.marks.slice(0, root.stack.length - 1);
        m[root.stack.length - 1] = root.current ? (root.current.label ?? "") : "";
        root.marks = m;
        root.stack = root.stack.concat([page]);
        root._enter();
    }

    // Ét lag tilbage. Er der ikke flere lag, er vi ude.
    function back(): void {
        if (root.prompt !== null) { root.prompt = null; return; }
        if (root.stack.length <= 1) { root.close(); return; }
        root.stack = root.stack.slice(0, -1);
        root.want = root.marks[root.stack.length - 1] ?? "";
        root.marks = root.marks.slice(0, root.stack.length - 1);
        root._enter();
    }

    // Escape. Ikke det samme som "tilbage": staar han der, hvor han kom ind,
    // er der ikke noget at gaa tilbage TIL, og saa lukker den.
    function esc(): void {
        if (root.prompt !== null) {
            // Var spoergsmaalet selv vejen ind, er der ikke noget bagved at gaa
            // tilbage til -- kun en menu han aldrig aabnede. Saa ud med det hele.
            if (root.promptEntry) { root.close(); return; }
            root.prompt = null;
            return;
        }
        if (root.stack.length <= root.entry) { root.close(); return; }
        root.back();
    }

    function close(): void {
        root.stack = [];
        root.entry = 1;
        root.promptEntry = false;
        root.marks = [];
        root.want = "";
        root.items = [];
        root.query = "";
        root.index = 0;
        root.status = "";
        root.prompt = null;
        root.closed();
    }

    // Samme side, nye tal. Filteret bliver staaende -- man har lige skrevet
    // det, og en handling maa ikke tage det fra én.
    function refresh(): void {
        if (!root.active) return;
        root.status = "henter...";
        root.stack[root.stack.length - 1].load();
    }

    function fill(list: var): void {
        root.items = list ?? [];
        root.status = "";
        if (root.index >= root.view.length) root.index = 0;
        // En side kan fylde ad flere omgange (et scan giver foerst en tom
        // liste). Derfor bliver oensket staaende, til linjen dukker op.
        if (root.want !== "") {
            const i = root.view.findIndex(it => (it.label ?? "") === root.want);
            if (i >= 0) { root.index = i; root.want = ""; }
        }
    }

    // `prefix` er med vilje utypet. Med `: string` goer QML et manglende
    // argument til STRENGEN "undefined", og saa stod der "undefined" foran
    // markoeren i stedet for "kode" hver eneste gang en aeldre kalder spurgte
    // om en adgangskode. Utypet bliver undefined ved med at vaere undefined,
    // og linjen nedenfor kan se forskel.
    function ask(title: string, masked: bool, submit: var, prefix: var, skift: var): void {
        root.prompt = {
            title: title,
            masked: masked,
            // Tomt prefix er et gyldigt valg, saa der skelnes paa undefined og
            // ikke paa tomhed. Kaldere fra foer det her felt fandtes spoerger
            // alle sammen om en kode.
            prefix: prefix === undefined ? "kode " : prefix,
            submit: submit,
            // Tab, mens der spoerges. Er den ikke sat, laver tab ingenting --
            // der er ikke noget at skifte imellem i en adgangskode.
            skift: skift,
            // Fyldes bagefter med noter(), hvis spoergsmaalet har en kontekst.
            note: ""
        };
        root.spoergNr = root.spoergNr + 1;
        // Standard er, at der er noget bagved. Den ene kalder, der aabner
        // feltet UDEFRA, saetter flaget selv bagefter.
        root.promptEntry = false;
    }

    // Ny overskrift paa det spoergsmaal der allerede staar. Teksten i feltet
    // bliver, hvor den er -- se spoergNr.
    function retitle(title: string): void { root._ret("title", title); }

    // Konteksten over feltet: hvad der sidst skete i den session, der tales
    // til. Den kommer ind ad samme vej som overskriften og af samme grund --
    // den frie linje aabner sig FOER svaret er hentet, og maa ikke vente paa
    // det. Se Pages.spoergClaude.
    function noter(note: string): void { root._ret("note", note); }

    // Skift ét felt paa det spoergsmaal, der staar. Objektet bygges om og
    // saettes helt: aendrer man en noegle i det, der allerede ligger, opdager
    // QML det ikke, og fladen bliver staaende med det gamle.
    function _ret(felt: string, vaerdi: var): void {
        if (root.prompt === null) return;
        const p = root.prompt;
        const n = {
            title: p.title,
            masked: p.masked,
            prefix: p.prefix,
            submit: p.submit,
            skift: p.skift,
            note: p.note ?? ""
        };
        n[felt] = vaerdi;
        root.prompt = n;
    }

    // Skriv i feltet uden at sende. Tomt er ikke en fejl -- det er bare
    // ingenting at laegge ind.
    function fyld(text: string): void {
        const t = (text ?? "").trim();
        if (t !== "") root.filled(t);
    }

    // Send feltet af sted uden at han roerer tastaturet. Kun naar der faktisk
    // staar et spoergsmaal -- ellers er der ikke noget at svare paa.
    function send(): void {
        if (root.prompt !== null) root.sender();
    }

    function answer(text: string): void {
        const p = root.prompt;
        root.prompt = null;
        if (p && p.submit) p.submit(text);
    }

    function move(delta: int): void {
        // Roerer han selv ved listen, er der ikke laengere noget at huske paa.
        root.want = "";
        const n = root.view.length;
        if (n === 0) return;
        root.index = (root.index + delta + n) % n;
    }

    function select(item: var): void {
        root.want = "";
        const i = root.view.indexOf(item);
        if (i >= 0) root.index = i;
    }

    // Vaelg en linje ved navn. Det er den vej udefra: Claude kan laese
    // listen og trykke paa en linje, praecis som Filip kan.
    function pick(label: string): bool {
        const needle = (label ?? "").trim().toLowerCase();
        if (needle === "") return false;
        const hit = root.items.find(i =>
            (i.label ?? "").toLowerCase().indexOf(needle) >= 0);
        if (!hit) return false;
        // Flyt ogsaa markeringen derhen. Ellers staar den et andet sted end
        // det, der bliver trykket paa -- og saa husker menuen den forkerte
        // linje, naar man gaar ind i et lag herfra.
        root.select(hit);
        root.activate(hit);
        return true;
    }

    // En linjes felter maa vaere funktioner i stedet for faste vaerdier. Saa
    // foelger de med af sig selv -- en kugle der viser hvad der er valgt, skal
    // ikke fryse paa det, der var valgt da siden blev bygget.
    function live(v: var): var {
        return (v instanceof Function) ? v() : v;
    }

    // Det der STAAR paa listen -- altsaa efter et eventuelt filter. Ellers
    // ville Claude laese en anden liste end den, der er paa skaermen.
    function labels(): var {
        return root.view.map(i => i.label ?? "");
    }

    function activate(item: var): void {
        const it = item ?? root.current;
        if (it && it.run) it.run();
    }

    function _enter(): void {
        root.query = "";
        root.index = 0;
        root.items = [];
        root.prompt = null;
        root.status = "henter...";
        root.stack[root.stack.length - 1].load();
    }

    function _filter(items, q) {
        const needle = (q ?? "").trim().toLowerCase();
        if (needle === "") return items ?? [];
        return (items ?? []).filter(i =>
            (i.label ?? "").toLowerCase().indexOf(needle) >= 0
            // hint maa vaere en funktion (se live()) -- uden den her stod
            // loggen fuld af toLowerCase-fejl, hver gang der blev soegt paa
            // en side hvor et hint retter sig selv.
            || (root.live(i.hint) ?? "").toLowerCase().indexOf(needle) >= 0);
    }
}

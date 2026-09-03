pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Spoergsmaalet om root-adgang.
//
// Alle tre trin bor i KROPPEN (flyttet 03-09 -- de to foerste laa i
// output-pillen indtil da):
//
//   vent    spoergsmaalet staar og venter paa at han er der. Ingen laeser er
//           taendt, ingen tid loeber. Det maa staa saa laenge det skal.
//   finger  han har trykket paa stroemknappen, og laeseren er aaben.
//   kode    fingeraftrykket gav op, og der skal tastes noget -- samme felt
//           som wifi-koden.
//
// Hvorfor kroppen og ikke output-pillen: det ER ganske vist maskinen der
// spoerger, men den beder om noget fra HAM, og et svar er input. Output-pillen
// har desuden kun én plads, og en besked der landede imens, tog den -- saa
// forsvandt spoergsmaalet, mens et script stod og ventede paa et svar. En
// besked kan komme igen; et spoergsmaal kan ikke. Se bar/SudoContent.qml.
//
// Hvorfor der er et tryk FOER laeseren: fingeraftryk kan ikke vente. PAM
// aabner laeseren i faa sekunder og giver op, og staar Filip ude i koekkenet,
// er spoergsmaalet doedt inden han naar tilbage. Trykket er ikke et samtykke
// -- det giver ingenting, og det kan ikke give root -- det siger kun "jeg er
// her, aabn den nu". Fingeren er stadig svaret.
//
// Trykket er stroemknappen, fordi laeseren SIDDER i stroemknappen paa den her
// maskine. Saa er det ét sted at roere: han trykker, og fingeren ligger
// allerede hvor den skal.
//
// Spoergsmaalet kommer udefra (~/.Scripts/claude-sudo-run) og svaret skal
// tilbage til et bash-script. Derfor to IPC-kald: rejs vender tilbage med det
// samme, og svaret hentes indtil der staar andet end "vent". Et kald der blev
// haengende, mens Filip taenkte sig om, ville fryse hele shellen imens.
//
// Hvert spoergsmaal har et nummer, og et nyt spoergsmaal overskriver altid det
// gamle. Foer sagde pillen "optaget" og lod kalderen falde tilbage til en
// zenity-dialog -- og saa var ét haengende spoergsmaal (en agent der blev
// draebt, foer den naaede at rydde op) nok til at hver eneste sudo resten af
// dagen aabnede en anden flade end pillen. Nu kan et gammelt spoergsmaal ikke
// spaerre for et nyt: den gamle ejer faar "vaek" og lukker sig selv.
//
// Der er ingen fallback laengere. Kan pillen ikke spoerge, koerer kommandoen
// ikke. Et root-spoergsmaal, der pludselig staar et andet sted end der hvor
// han kigger, er vaerre end et der ikke bliver stillet.
//
// Tre udfald, ikke to: ja, nej, og "han svarede aldrig". Det sidste skal
// betyde nej -- en privilegeret kommando maa aldrig slippe igennem, fordi et
// spoergsmaal forsvandt.
Singleton {
    id: root

    // Kommandoen der ligger til godkendelse. Tom = ingen forespoergsel.
    property string cmd: ""
    property string kind: ""
    // Nummeret paa det spoergsmaal der staar nu. Tomt = ingen. Kalderen faar
    // det udleveret naar den rejser, og skal vise det frem hver gang den
    // spoerger til svaret -- ellers kan den ikke vide, om den taler om sit
    // eget spoergsmaal eller om et der har afloest det.
    property string nr: ""
    property int _seq: 0
    // Staar tom indtil der er svaret. done skiller "intet svar endnu" fra
    // "svarede med en tom kode".
    property string result: ""
    property bool done: false
    // PAM tog imod fingeren. Bliver staaende et oejeblik, saa han kan se at
    // det lykkedes, i stedet for at slutte det af at der ikke skete noget.
    property bool accepted: false

    readonly property bool pending: root.kind !== "" && !root.done
    // Ventende og aaben laeser ser ens ud udefra: begge er spoergsmaalet, mens
    // det staar. Det output-pillen gaar efter -- spoergsmaalet, og
    // kvitteringen lige efter.
    readonly property bool showing:
        (root.kind === "vent" || root.kind === "finger")
        && (root.pending || root.accepted)

    // Foerst sandt naar kode-feltet faktisk staar der. Uden det ville
    // Menu.open()'s egen nulstilling af feltet blive laest som "fortrudt",
    // og spoergsmaalet lukke sig selv i samme oejeblik det blev rejst.
    property bool _asked: false

    // Rejs. Overskriver altid -- se noten oeverst.
    function rejs(command: string): string {
        root._seq += 1;
        root.nr = String(root._seq);
        root.cmd = command;
        root.kind = "vent";
        root.result = "";
        root.done = false;
        root.accepted = false;
        root._asked = false;
        kvittering.stop();
        if (Menu.active && Menu.title === "sudo") Menu.close();
        return root.nr;
    }

    // "Jeg er her." Aabner laeseren, og ikke en tomme mere: det er ikke et ja,
    // og et tryk ved en fejl koster ingenting -- fingeren mangler stadig.
    function klar(): bool {
        if (root.kind !== "vent" || root.done) return false;
        root.kind = "finger";
        return true;
    }

    function kode(command: string): void {
        root.cmd = command;
        root.kind = "kode";
        root.result = "";
        root.done = false;
        root.accepted = false;
        root._asked = false;
        kvittering.stop();
        Launcher.close();
        Pill.modal(Pages.sudoPage());
        Menu.ask("adgangskode", true, text => root.besvar("ja:" + text));
        root._asked = true;
    }

    // Kvitteringen. Lukkede fladen i samme oejeblik, ville bekraeftelsen vaere
    // et glimt man ikke naaede at se -- og saa var den ikke en bekraeftelse.
    function godkendt(): void {
        if (root.kind !== "finger" || root.done) return;
        root.accepted = true;
        root.result = "ja";
        root.done = true;
        kvittering.restart();
    }

    // Kaldes af kode-feltet, og af hoejreklik paa spoergsmaalet.
    function besvar(value: string): void {
        if (root.done || root.kind === "") return;
        root.result = value;
        root.done = true;
        if (root.kind === "kode" && Menu.active) Menu.close();
    }

    // Ryd op uden at svare -- scriptet gav op og venter ikke laengere.
    function afbryd(): void {
        root.kind = "";
        root.cmd = "";
        root.nr = "";
        root.result = "";
        root.done = false;
        root.accepted = false;
        root._asked = false;
        kvittering.stop();
        if (Menu.active && Menu.title === "sudo") Menu.close();
    }

    // Et hak efter at kode-feltet forsvandt. Er der stadig ikke svaret, var
    // det en fortrydelse -- og saa er der ikke noget tilbage at se paa.
    function fortrudt(): void {
        if (root.pending && root.kind === "kode" && Menu.prompt === null)
            Menu.close();
    }

    Timer {
        id: kvittering
        interval: Config.sudoKvittering
        repeat: false
        onTriggered: root.accepted = false;
    }

    // Kode-feltet ligger i menuen, og menuen kan lukke sig selv: escape, klik
    // udenfor, diktering der starter. Uden svar er det et nej.
    Connections {
        target: Menu
        function onClosed(): void {
            if (root.pending && root.kind === "kode") {
                root.result = "nej";
                root.done = true;
            }
        }
        // Gotcha: Menu.answer() rydder feltet FOER den kalder submit, saa et
        // svar ser i det oejeblik praecis ud som en fortrydelse. Derfor et hak
        // senere -- er der stadig ikke svaret, var det en fortrydelse.
        function onPromptChanged(): void {
            if (root.pending && root.kind === "kode" && root._asked
                && Menu.prompt === null)
                Qt.callLater(root.fortrudt);
        }
    }

    IpcHandler {
        target: "sudo"

        // Rejser et spoergsmaal og vender tilbage med nummeret paa det.
        function rejs(command: string): string {
            return root.rejs(command);
        }

        // Stroemknappen. Svarer "ja" hvis der var noget at aabne, saa den der
        // trykkede kan afgoere om trykket betoed noget -- én knap, én mening,
        // og pillen ved selv hvad der er i gang. Samme moenster som
        // `pill afbryd`.
        function klar(): string {
            return root.klar() ? "ja" : "ingenting";
        }

        // Fingeraftrykket gav op, og der skal tastes. Samme spoergsmaal, der
        // gaar videre til naeste led -- derfor kraever den kun at nummeret
        // stadig passer, ikke at der er ryddet op foerst. Sagde vi nej her,
        // endte det med "sudo: no password was provided": sudo spurgte om en
        // kode, som pillen naegtede at vise.
        function kode(nr: string, command: string): string {
            if (nr !== root.nr || root.nr === "") return "vaek";
            root.kode(command);
            return "spurgt";
        }

        // Kaldes af sudo-pty i det oejeblik PAM tog imod fingeren.
        function godkendt(nr: string): string {
            if (nr !== root.nr || root.nr === "") return "vaek";
            root.godkendt();
            return "kvitteret";
        }

        // Svaret paa ét bestemt spoergsmaal. "vaek" betyder at et nyt har
        // afloest det -- saa er der ingen der venter paa det her laengere.
        //
        // Svaret bliver STAAENDE. Det plejede at blive ryddet ved foerste
        // hentning, og det var en fejl med taender i: naar fingeraftrykket
        // fejler, staar der to og spoerger paa én gang -- vagten og askpass --
        // og saa vandt den ene kaploebet om adgangskoden, mens den anden fik
        // ingenting og meldte afbud. Nu ser de det samme.
        function svar(nr: string): string {
            if (nr !== root.nr || root.nr === "") return "vaek";
            if (root.done) return root.result;
            return root.kind === "vent" ? "vent" : "klar";
        }

        // Vagtens vej ind. Den koerer i baggrunden hele vejen igennem og skal
        // kun vide én ting: blev der sagt nej? Derfor gaar adgangskoden ALDRIG
        // gennem den her -- den har ikke brug for den til noget, og en kode
        // der ligger i en baggrundsproces er en kode for meget.
        //
        // "slut" betyder hold op med at holde oeje: enten er der svaret ja, og
        // saa koerer kommandoen nu og maa ikke draebes, eller ogsaa er
        // spoergsmaalet vaek.
        function vagt(nr: string): string {
            if (nr !== root.nr || root.nr === "") return "slut";
            if (!root.done) return "venter";
            return root.result === "nej" ? "nej" : "slut";
        }

        // Ryd op -- men kun sit eget. Uden nummeret kunne en oprydning fra et
        // forloeb, der forlaengst var afloest, taske et spoergsmaal Filip lige
        // havde faaet stillet.
        function afbryd(nr: string): string {
            if (nr !== root.nr || root.nr === "") return "vaek";
            root.afbryd();
            return "ryddet";
        }

        function state(): string {
            if (root.nr === "") return "ingenting";
            if (root.accepted) return `godkendt (${root.nr})`;
            if (root.done) return `svaret (${root.nr})`;
            return `venter (${root.kind}, ${root.nr})`;
        }
    }
}

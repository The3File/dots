pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Spoergsmaalet om root-adgang.
//
// Det bor to steder, og delingen er den samme som i resten af fladen: kroppen
// er det Filip GOER, output-pillen er det der SKER for ham.
//
//   finger  maskinen spoerger. Den lander i output-pillen ved siden af
//           kroppen, som en besked -- for det er ikke noget han er i gang
//           med, og det maa ikke skubbe det han laver til side. Ingen menu,
//           intet tastatur, ingen knap at trykke ja paa: fingeren ER svaret.
//   kode    fingeraftrykket gav op, og der skal tastes noget. Det er input,
//           og saa hoerer det hjemme i kroppen -- samme felt som wifi-koden.
//
// Fingeren er samtykket. Der var foer et ja/nej og et fingeraftryk bagefter;
// det er den samme sikkerhed spurgt to gange, og det foerste spoergsmaal er
// praecis det man laerer at klikke vaek uden at laese.
//
// Spoergsmaalet kommer udefra (~/.Scripts/claude-sudo-run) og svaret skal
// tilbage til et bash-script. Derfor to IPC-kald: rejs vender tilbage med det
// samme, og svaret hentes indtil der staar andet end "venter". Et kald der
// blev haengende, mens Filip taenkte sig om, ville fryse hele shellen imens.
//
// Tre udfald, ikke to: ja, nej, og "han svarede aldrig". Det sidste skal
// betyde nej -- en privilegeret kommando maa aldrig slippe igennem, fordi et
// spoergsmaal forsvandt.
Singleton {
    id: root

    // Kommandoen der ligger til godkendelse. Tom = ingen forespoergsel.
    property string cmd: ""
    property string kind: ""
    // Staar tom indtil der er svaret. done skiller "intet svar endnu" fra
    // "svarede med en tom kode".
    property string result: ""
    property bool done: false
    // PAM tog imod fingeren. Bliver staaende et oejeblik, saa han kan se at
    // det lykkedes, i stedet for at slutte det af at der ikke skete noget.
    property bool accepted: false

    readonly property bool pending: root.kind !== "" && !root.done
    // Det output-pillen gaar efter: spoergsmaalet mens det staar, og
    // kvitteringen lige efter.
    readonly property bool showing: root.kind === "finger" && (root.pending || root.accepted)

    // Foerst sandt naar kode-feltet faktisk staar der. Uden det ville
    // Menu.open()'s egen nulstilling af feltet blive laest som "fortrudt",
    // og spoergsmaalet lukke sig selv i samme oejeblik det blev rejst.
    property bool _asked: false

    function finger(command: string): void {
        root._rejs("finger", command);
    }

    function kode(command: string): void {
        root._rejs("kode", command);
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

    function _rejs(k: string, command: string): void {
        root.cmd = command;
        root.kind = k;
        root.result = "";
        root.done = false;
        root.accepted = false;
        root._asked = false;
        kvittering.stop();
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

        // Rejser et spoergsmaal og vender tilbage med det samme. "optaget"
        // hvis der allerede ligger et ubesvaret -- saa falder kalderen tilbage
        // til zenity i stedet for at overskrive noget Filip staar og laeser.
        function finger(command: string): string {
            if (root.pending) return "optaget";
            root.finger(command);
            return "spurgt";
        }
        // Et fingeraftryk der staar og venter, maa gerne vige for koden: det
        // er ikke et konkurrerende spoergsmaal, det er det SAMME spoergsmaal
        // der er gaaet videre til naeste led, fordi laeseren gav op. Sagde vi
        // "optaget" her, endte det med "no password was provided" — sudo
        // spurgte om en kode, som pillen naegtede at vise.
        function kode(command: string): string {
            if (root.pending && root.kind !== "finger") return "optaget";
            root.kode(command);
            return "spurgt";
        }

        // Kaldes af sudo-pty i det oejeblik PAM tog imod fingeren.
        function godkendt(): string {
            root.godkendt();
            return "kvitteret";
        }

        // "ingenting" og ikke "nej" naar der ikke staar noget: vagten i
        // claude-sudo-run bliver ved med at spoerge, mens kommandoen koerer,
        // og et "nej" der bare betoed "der er ikke noget spoergsmaal" ville
        // faa den til at draebe en kommando han lige havde godkendt.
        //
        // Svaret bliver STAAENDE. Det plejede at blive ryddet ved foerste
        // hentning, og det var en fejl med taender i: naar fingeraftrykket
        // fejler, staar der to og spoerger paa én gang — vagten og askpass —
        // og saa vandt den ene kapløbet om adgangskoden, mens den anden fik
        // "ingenting" og meldte afbud. Nu ser de det samme, og et nyt
        // spoergsmaal nulstiller alligevel selv.
        function svar(): string {
            if (root.kind === "") return "ingenting";
            if (!root.done) return "venter";
            return root.result;
        }

        // Blev der sagt nej? Det eneste vagten i claude-sudo-run har brug for
        // at vide — og saa slipper en adgangskode for at gaa gennem en
        // baggrundsproces, der ikke skal bruge den til noget.
        function afvist(): string {
            return (root.done && root.result === "nej") ? "ja" : "nej";
        }

        function afbryd(): void { root.afbryd(); }

        function state(): string {
            if (root.kind === "") return "ingenting";
            if (root.accepted) return "godkendt";
            return root.done ? "svaret" : `venter (${root.kind})`;
        }
    }
}

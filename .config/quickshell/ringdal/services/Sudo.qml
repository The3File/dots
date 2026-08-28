pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Adgangsspoergsmaalet i pillen i stedet for et fremmed vindue.
//
// Spoergsmaalet kommer udefra (~/.Scripts/claude-sudo-run) og svaret skal
// tilbage til et bash-script. Derfor er det delt i to kald: spoerg() rejser
// spoergsmaalet og vender tilbage med det samme, og svar() kan hentes igen og
// igen indtil der staar andet end "venter". Et IPC-kald der blev haengende
// mens Filip taenkte sig om, ville fryse hele shellen imens.
//
// Der er tre udfald, ikke to: ja, nej, og "han svarede aldrig". Det sidste
// sker naar pillen bliver lukket af noget andet -- et klik udenfor, eller
// diktering der starter -- og det skal betyde nej. En privilegeret kommando
// maa aldrig slippe igennem, fordi et spoergsmaal forsvandt.
Singleton {
    id: root

    // Kommandoen der ligger til godkendelse. Tom = ingen forespoergsel.
    property string cmd: ""
    // "finger" = laeg fingeren, og det er svaret. "kode" = fingeraftrykket gav
    // op, skriv koden. "valg" = tillad/afvis med to linjer; den bruges ikke
    // laengere til root-adgang, men motoren kan den, og den koster ingenting.
    //
    // Fingeren ER samtykket. Et ja foerst og en finger bagefter er at spoerge
    // om det samme to gange -- og det andet spoergsmaal laerer man at klikke
    // vaek uden at laese det.
    property string kind: ""
    // Fingeren blev godkendt. Staar kort paa fladen, saa han kan se at det
    // lykkedes, i stedet for at gaette ud fra at der ikke skete noget.
    property bool accepted: false
    // Staar tom indtil der er svaret. done skiller "intet svar endnu" fra
    // "svarede med en tom kode".
    property string result: ""
    property bool done: false

    readonly property bool pending: root.kind !== "" && !root.done
    // Foerst sandt naar kode-feltet faktisk staar der. Uden det ville
    // Menu.open()'s egen nulstilling af feltet blive laest som "fortrudt",
    // og spoergsmaalet lukke sig selv i samme oejeblik det blev rejst.
    property bool _asked: false

    function spoerg(command: string): void {
        root._rejs("valg", command);
    }

    function finger(command: string): void {
        root._rejs("finger", command);
    }

    // PAM tog imod fingeren. Kvitter paa fladen, og lad den staa et oejeblik --
    // lukkede den med det samme, ville bekraeftelsen vaere et glimt man ikke
    // naaede at se, og saa var den ikke en bekraeftelse.
    function godkendt(): void {
        if (root.kind !== "finger" || root.done) return;
        root.accepted = true;
        root.result = "ja";
        root.done = true;
        Menu.status = "godkendt";
        Menu.statusColor = Theme.stateGood;
        kvittering.restart();
    }

    Timer {
        id: kvittering
        interval: Config.sudoKvittering
        repeat: false
        onTriggered: if (Menu.active) Menu.close();
    }

    function kode(command: string): void {
        root._rejs("kode", command);
        Menu.ask("adgangskode", true, text => root.besvar("ja:" + text));
        root._asked = true;
    }

    // Ryd op uden at svare -- scriptet gav op og venter ikke laengere.
    function afbryd(): void {
        root.kind = "";
        root.cmd = "";
        root.accepted = false;
        root.done = false;
        root.result = "";
        kvittering.stop();
        if (Menu.active) Menu.close();
    }

    function _rejs(k: string, command: string): void {
        root.cmd = command;
        root.kind = k;
        root.accepted = false;
        root._asked = false;
        root.result = "";
        root.done = false;
        Launcher.close();
        Pill.modal(Pages.sudoPage());
    }

    // Et hak efter at kode-feltet forsvandt. Er der stadig ikke svaret, var
    // det en fortrydelse -- og saa er der ikke noget tilbage at se paa.
    function fortrudt(): void {
        if (root.pending && root.kind === "kode" && Menu.prompt === null)
            Menu.close();
    }

    // Kaldes af linjerne paa siden, og af kode-feltet.
    function besvar(value: string): void {
        if (root.done || root.kind === "") return;
        root.result = value;
        root.done = true;
        Menu.close();
    }

    // Menuen lukkede uden svar: det er et nej.
    Connections {
        target: Menu
        function onClosed(): void {
            if (root.pending) { root.result = "nej"; root.done = true; }
        }
        // Fortryder han kode-feltet, er der ikke noget tilbage at se paa.
        //
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

        // Begge rejser et spoergsmaal og vender med det samme. "optaget" hvis
        // der allerede ligger et ubesvaret -- saa falder kalderen tilbage til
        // zenity i stedet for at overskrive noget Filip staar og laeser paa.
        function spoerg(command: string): string {
            if (root.pending) return "optaget";
            root.spoerg(command);
            return "spurgt";
        }
        function kode(command: string): string {
            if (root.pending) return "optaget";
            root.kode(command);
            return "spurgt";
        }
        function finger(command: string): string {
            if (root.pending) return "optaget";
            root.finger(command);
            return "spurgt";
        }

        // Kaldes af sudo-pty i det oejeblik PAM tog imod fingeren.
        function godkendt(): string {
            root.godkendt();
            return "kvitteret";
        }

        // "venter" | "ja" | "nej" | "ja:<kode>". Svaret hentes én gang og
        // ryddes, saa det naeste spoergsmaal starter forfra.
        // "ingenting" og ikke "nej" naar der ikke staar noget: vagten i
        // claude-sudo-run bliver ved med at spoerge, mens kommandoen koerer,
        // og et "nej" der bare betoed "der er ikke noget spoergsmaal" ville
        // faa den til at draebe en kommando han lige havde godkendt.
        function svar(): string {
            if (root.kind === "") return "ingenting";
            if (!root.done) return "venter";
            const ud = root.result;
            root.kind = "";
            root.cmd = "";
            root.done = false;
            root.result = "";
            return ud;
        }

        function afbryd(): void { root.afbryd(); }

        function state(): string {
            if (root.kind === "") return "ingenting";
            return root.done ? "svaret" : `venter (${root.kind})`;
        }
    }
}

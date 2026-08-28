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
    // "valg" = tillad/afvis. "kode" = fingeraftrykket gav op, skriv koden.
    property string kind: ""
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

    function kode(command: string): void {
        root._rejs("kode", command);
        Menu.ask("adgangskode", true, text => root.besvar("ja:" + text));
        root._asked = true;
    }

    // Ryd op uden at svare -- scriptet gav op og venter ikke laengere.
    function afbryd(): void {
        root.kind = "";
        root.cmd = "";
        root.done = false;
        root.result = "";
        if (Menu.active) Menu.close();
    }

    function _rejs(k: string, command: string): void {
        root.cmd = command;
        root.kind = k;
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

        // "venter" | "ja" | "nej" | "ja:<kode>". Svaret hentes én gang og
        // ryddes, saa det naeste spoergsmaal starter forfra.
        function svar(): string {
            if (root.kind === "") return "nej";
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

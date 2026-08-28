pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Agentfladen. Hvad Claude er i gang med, mens Filip kigger et andet sted hen.
//
// Det her er den eneste del af shellen der viser noget han ikke kunne se i
// forvejen. Beskeder fortaeller at noget er *sket*; den her fortaeller at noget
// *sker* -- og hvad. Uden den er en lang opgave bare stilhed indtil den er
// faerdig.
//
// Linjerne kommer fra `tale` (AIOS/tale/tale), de samme korte saetninger han
// hoerer naar oplaesningen er slaaet til. Det er med vilje: linjen er
// informationen, stemmen og pillen er to maader at levere den paa. Derfor
// skubber `tale` hertil FOER den tjekker om oplaesning er taendt.
//
// Tre tilstande, ikke flere:
//   ledig     der sker ingenting. Pillen viser ingenting.
//   arbejder  koerer. Staar i kroppen -- det er handlingen der er i gang.
//   venter    har brug for ham. Staar i afvigelses-pillen -- det er noget han
//             skal reagere paa, og det maa ikke kunne skjules af en aaben menu.
Singleton {
    id: root

    property string state: "ledig"
    property string line: ""
    // Niveauet fra tale: "frem" (normal), "obs" (noget uventet).
    property string level: "frem"

    readonly property bool working: root.state === "arbejder"
    readonly property bool waiting: root.state === "venter"
    // Linjen vises begge veje. Afvigelses-pillen garanterer at "venter" bliver
    // set; kroppen baerer ordene. Uden begge dele ved han enten ikke at han
    // skal reagere, eller ikke hvad det handler om.
    readonly property bool showing: (root.working || root.waiting) && root.line !== ""

    readonly property color color: {
        if (root.waiting) return Theme.stateBad;
        if (root.level === "obs") return Theme.stateWarn;
        return Theme.color6;
    }

    function say(level: string, text: string): void {
        const t = (text ?? "").trim();
        if (t === "") return;
        root.level = (level === "obs" || level === "dig") ? level : "frem";
        root.line = t;
        // "dig" betyder at der er brug for ham nu -- det er ikke et niveau, det
        // er en tilstand.
        if (root.level === "dig") root.state = "venter";
        // En linje er i sig selv bevis paa at der koeres. Uden det ville en
        // tur der starter uden om UserPromptSubmit staa som ledig.
        else if (root.state === "ledig") root.state = "arbejder";
    }

    function working_(): void { root.state = "arbejder"; }
    function waiting_(): void { root.state = "venter"; }

    function done(): void {
        root.state = "ledig";
        root.line = "";
        root.level = "frem";
    }

    IpcHandler {
        target: "agent"

        function say(level: string, text: string): void { root.say(level, text); }
        function working(): void { root.working_(); }
        function waiting(): void { root.waiting_(); }
        function done(): void { root.done(); }
        function state(): string {
            return root.line === "" ? root.state : `${root.state}: ${root.line}`;
        }
    }
}

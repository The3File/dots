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
        root.opened = true;
        root.peeking = false;
        if (name === "wifi") Menu.open2(Pages.rootPage(), Pages.wifiPage());
        else if (name === "bt") Menu.open2(Pages.rootPage(), Pages.btPage());
        else if (name === "notifs") Menu.open2(Pages.rootPage(), Pages.notifsPage());
        else Menu.open(Pages.rootPage());
    }

    function notifs(): void { root.enter("notifs"); }

    // Esc gaar ét lag tilbage foer den lukker -- man skal ikke miste hele
    // menuen fordi man fortroed at gaa ind i wifi.
    function back(): void {
        if (Menu.active) Menu.back(); else root.close();
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
        function wifi(): void { root.enter("wifi"); }
        function bluetooth(): void { root.enter("bt"); }
        function beskeder(): void { root.enter("notifs"); }
        // Menuen udefra: se hvad der staar, og tryk paa en linje.
        function items(): string {
            if (!Menu.active) return "menuen er lukket";
            return Menu.labels().join("\n");
        }
        function pick(label: string): string {
            if (!Menu.active) return "menuen er lukket";
            return Menu.pick(label) ? `valgte: ${label}` : `fandt ikke: ${label}`;
        }

        function state(): string {
            if (!root.opened) return "closed";
            return Menu.title === "" ? "open" : Menu.title;
        }
    }
}

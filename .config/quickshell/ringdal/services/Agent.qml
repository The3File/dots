pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Agentfladen. Kun ét spoergsmaal: koerer der noget, og skal du gribe ind?
//
// Foerste udgave viste ogsaa den seneste talte linje i kroppen. Det var forkert
// to gange. Kroppen er INPUT -- det Filip putter ind i maskinen: stemmen,
// menuen, aabneren. Det her er output, og output hoerer til i pillen ved siden
// af. Og linjerne var skrevet til oeret: en talt saetning er lavet til at
// passere, ikke til at blive staaende og laeses.
//
// Saa ordene gaar gennem beskedfladen (den bobler op og traekker sig, og har en
// liste bagefter), og det eneste der bliver tilbage her er en prik.
//
// Prikken er ikke pynt. Den er svaret paa det spoergsmaal der foer kraevede
// konstant snak: er der stadig liv? Uden den var stilhed tvetydig, og derfor
// stod der "stilhed er fejlen" i tale. Med den kan stemmen tie.
Singleton {
    id: root

    property string state: "ledig"
    // Hvornaar der sidst kom livstegn. Uden det kan pillen staa og sige
    // "arbejder" i timevis, fordi en session doede uden at sige farvel.
    property double lastSeen: 0

    readonly property bool working: root.state === "arbejder"
    readonly property bool waiting: root.state === "venter"
    readonly property bool active: root.working || root.waiting

    // Gaaet i staa? Prikken holder op med at aande, men bliver staaende --
    // "der er noget der ikke er lukket ned" er ogsaa information.
    property bool stale: false

    readonly property color color: root.waiting ? Theme.stateBad
        : (root.stale ? Theme.color8 : Theme.color6)

    function _touch(): void {
        root.lastSeen = Date.now();
        root.stale = false;
        staleTimer.restart();
    }

    Timer {
        id: staleTimer
        interval: Config.agentStale
        repeat: false
        onTriggered: root.stale = true
    }

    IpcHandler {
        target: "agent"

        function working(): void { root.state = "arbejder"; root._touch(); }
        function waiting(): void { root.state = "venter"; root._touch(); }
        function done(): void {
            root.state = "ledig";
            root.stale = false;
            staleTimer.stop();
        }
        function state(): string { return root.stale ? `${root.state} (stille)` : root.state; }
    }
}

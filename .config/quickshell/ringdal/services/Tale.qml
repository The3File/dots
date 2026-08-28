pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Taleindikatoren. Ét spoergsmaal: bliver der sagt noget lige nu, og ligger
// der mere bagved?
//
// Prikken ved siden af siger at Claude arbejder. Det her siger noget andet:
// at der bliver TALT. De to skal kunne skelnes uden at man laeser, og derfor
// er bevaegelsen forskellig -- prikken aander, det her svinger som lyd goer.
//
// Grunden til at den overhovedet findes: stemmen kan koere i lang tid, og der
// var ingen maade at komme videre paa uden at goere helt tavs. Nu kan en
// enkelt linje springes over, og indikatoren er det synlige klikmaal.
//
// Tallet er ikke pynt. Det er det eneste her, der aendrer hvad han goer: er
// det den sidste linje, venter man den ud -- ligger der fem bagved, springer
// man over.
Singleton {
    id: root

    // Bliver der talt lige nu?
    property bool talking: false
    // Hvor mange linjer ligger der EFTER den, der laeses nu.
    property int queued: 0

    readonly property string label: root.queued > 0 ? `taler ·${root.queued}` : "taler"

    // Spring den linje over, der laeses nu. Koeen fortsaetter af sig selv.
    function skip(): void {
        skipper.running = false;
        skipper.command = [root._tale, "spring"];
        skipper.running = true;
    }

    // Gør helt tavs og toem koeen. Det er den store gestus -- hold nede.
    function silence(): void {
        skipper.running = false;
        skipper.command = [root._tale, "stop"];
        skipper.running = true;
        root.talking = false;
        root.queued = 0;
        staleTimer.stop();
    }

    readonly property string _tale: `${Config.home}/.local/bin/tale`

    Process { id: skipper }

    // Vagthund, samme moenster som prikkens. Doer afspilleren uden at naa at
    // sige farvel, ville "taler" ellers staa for evigt. Der gaettes ikke paa
    // det med en timer alene: der spoerges.
    Timer {
        id: staleTimer
        interval: Config.taleStale
        repeat: false
        onTriggered: if (!alive.running) alive.running = true
    }

    Process {
        id: alive
        command: [root._tale, "__taler"]
        onExited: (code, status) => {
            if (code === 0) {
                // Afspilleren lever -- en lang linje er bare ikke faerdig.
                staleTimer.restart();
            } else {
                root.talking = false;
                root.queued = 0;
            }
        }
    }

    IpcHandler {
        target: "tale"

        function taler(koe: string): void {
            root.talking = true;
            root.queued = Math.max(0, parseInt(koe, 10) || 0);
            staleTimer.restart();
        }

        function tavs(): void {
            root.talking = false;
            root.queued = 0;
            staleTimer.stop();
            alive.running = false;
        }

        function spring(): void { root.skip(); }
        function stille(): void { root.silence(); }

        function state(): string {
            return root.talking ? `taler (${root.queued} i koe)` : "tavs";
        }
    }
}

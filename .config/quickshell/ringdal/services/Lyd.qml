pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

// Hvilke lydenheder der findes, og hvilken der er valgt.
//
// Audio.qml er lydstyrken paa den valgte udgang; den her er valget selv --
// hoejttaler eller headset, den ene mikrofon eller den anden. Delt op fordi de
// aendrer sig af hver sin grund: styrken hele tiden, enheden sjaeldent.
//
// Listen og den aktuelle enhed kommer fra Pipewire-modulet, som opdaterer sig
// selv -- en wpctl-poll ville vaere den daarligere af de to.
//
// SELVE SKIFTET gaar gennem `pactl`, og det er ikke sjusk: Quickshells
// `preferredDefaultAudioSink` er kun shellens egen foretrukne, den skriver
// ikke Pipewires metadata (maalt -- den valgte node stod som "preferred" mens
// systemets default blev liggende). btcon flytter i forvejen lydudgangen med
// `pactl set-default-sink`, saa det er ogsaa den vej, resten af maskinen
// allerede bruger.
Singleton {
    id: root

    // Typerne er bitflag. Vi sammenligner mod de navngivne konstanter i
    // stedet for tal, saa det ikke knaekker hvis vaerdierne flytter sig.
    // Stroemme (en browser der spiller lyd) er ikke enheder og skal ud.
    function _is(node, flag): bool {
        return node !== null && !node.isStream && (node.type & flag) === flag;
    }

    readonly property var nodes: Pipewire.nodes?.values ?? []
    readonly property var sinks: root.nodes.filter(n => root._is(n, PwNodeType.AudioSink))
    readonly property var sources: root.nodes.filter(n => root._is(n, PwNodeType.AudioSource))

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Navnet i listen. ALSA skriver hele lydkortet med i hver eneste enhed --
    // "Ryzen HD Audio Controller Stereo Microphone" -- og kortet er det samme
    // for dem alle, saa det siger ingenting og aeder linjen. Profilnavnet er
    // det der faktisk skiller dem ad: "Stereo Microphone", "Speaker".
    //
    // Kun for ALSA. Et bluetooth-headset har sit eget navn i description, og
    // dets profilnavn er noget i retning af "High Fidelity Playback (A2DP)".
    // Kaldenavnet duer heller ikke -- mikrofonerne her hedder "ALC257 Analog".
    function navn(node): string {
        if (!node) return "";
        const p = node.properties ?? {};
        if (p["device.api"] === "alsa" && (p["device.profile.description"] ?? "") !== "")
            return p["device.profile.description"];
        return node.description !== "" ? node.description : node.name;
    }

    function saetUdgang(node): void {
        root._pactl("set-default-sink", node);
    }

    function saetIndgang(node): void {
        root._pactl("set-default-source", node);
    }

    // Et valg der ikke gik igennem. Se timeren nedenfor.
    signal afvist(navn: string)

    property var _oensket: null

    // node.name er det samme navn pactl kender enheden under.
    function _pactl(kommando: string, node): void {
        if (!node || node.name === "") return;
        root._oensket = node;
        skift.command = ["pactl", kommando, node.name];
        skift.running = true;
        tjek.restart();
    }

    Process { id: skift }

    // pactl svarer ja, ogsaa naar det ikke skete. En enhed hvis stik er tomt
    // -- mikrofonen i hovedtelefonudtaget -- staar paa listen, men WirePlumber
    // naegter at goere den til standard, og saa bliver den gamle liggende.
    // Uden det her ville et klik paa den linje bare ikke goere noget.
    Timer {
        id: tjek
        interval: 1200
        onTriggered: {
            const node = root._oensket;
            root._oensket = null;
            if (!node || node === root.sink || node === root.source) return;
            root.afvist(root.navn(node));
        }
    }

    // Uden en tracker er noderne ikke bundet, og saa er beskrivelserne tomme
    // -- listen ville staa med navne som "alsa_output.pci-0000_04_00.6".
    PwObjectTracker { objects: root.sinks.concat(root.sources) }
}

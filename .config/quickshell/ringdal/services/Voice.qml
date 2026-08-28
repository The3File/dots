pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Stemmesloejfen. Ejer tilstanden; ingen visuel kode her.
//
// Kilden er hyprwhsprs egne runtime-filer, ikke et statusscript. Motoren
// skriver dem selv under optagelse -- visualizer_state ved hvert skift,
// audio_level ti gange i sekundet -- saa vi behoever hverken at starte en
// proces eller vaekke python for at vide hvad der sker.
//
// audio_level findes kun mens der optages; den slettes bagefter. Det er ikke
// en fejl, det er hviletilstanden.
Singleton {
    id: root

    readonly property string runtimeDir:
        `${Quickshell.env("XDG_RUNTIME_DIR")}/hyprwhspr`

    // recording | paused | processing | error | success | "" (hviler)
    readonly property string mode: stateFile.text.trim().toLowerCase()

    readonly property bool listening: mode === "recording"
    readonly property bool paused: mode === "paused"
    readonly property bool thinking: mode === "processing"
    readonly property bool failed: mode === "error"
    readonly property bool succeeded: mode === "success"
    // Naar fladen overhovedet skal vaere fremme.
    readonly property bool active: mode !== ""

    // Ét ord til fladen. Dansk, fordi det er en dansk maskine og det bliver
    // laest af et menneske -- ikke af waybar.
    readonly property string label: {
        if (root.listening) return "lytter";
        if (root.paused) return "pause";
        if (root.thinking) return "taenker";
        if (root.failed) return "fejl";
        if (root.succeeded) return "klar";
        return "";
    }

    readonly property color color: {
        if (root.failed) return Theme.stateBad;
        if (root.thinking) return Theme.stateBusy;
        if (root.succeeded) return Theme.stateGood;
        if (root.paused) return Theme.color8;
        return Theme.color4;
    }

    // Udslag 0..1, glattet. Det er den ene vaerdi boelgen tegnes af.
    readonly property real level: _level
    property real _level: 0

    // ---- omregning fra raa lydstyrke til udslag ---------------------------
    // Portet fra ~/.Scripts/hyprwhspr_osd_patches.py, som gav den stille
    // laptop-mikrofon noget at vise. Tallene er de samme; kun indgangen er en
    // anden. Patchen regnede paa raa RMS pr. bucket, mens audio_level allerede
    // er ganget med 10 -- derfor 7,5 her hvor patchen havde 75.
    readonly property real gain: 7.5
    readonly property real gamma: 0.78
    readonly property real noiseGate: 0.24
    readonly property real riseRate: 0.68
    readonly property real decayRate: 0.80

    function _shape(raw: real): real {
        // Forstaerk, og traek kurven op saa stille tale ogsaa giver udslag.
        let v = Math.pow(Math.max(0, raw) * root.gain, root.gamma);
        v = Math.min(1, v);
        // Stoejporten: traek grænsen fra og stræk resten ud igen, saa tale
        // stadig naar helt op.
        const denom = Math.max(1e-6, 1 - root.noiseGate);
        return Math.max(0, Math.min(1, (v - root.noiseGate) / denom));
    }

    // Hurtigt op, langsomt ned -- ellers blinker boelgen mellem stavelser.
    function _smooth(target: real): void {
        let v = root._level;
        if (target > v) {
            v = root.riseRate * target + (1 - root.riseRate) * v;
        } else {
            v = v * root.decayRate;
            if (v < target) v = target;
        }
        root._level = v < 0.02 ? 0 : v;
    }

    TextFile {
        id: stateFile
        file: `${root.runtimeDir}/visualizer_state`
        interval: Config.voiceStateInterval
    }

    TextFile {
        id: levelFile
        file: `${root.runtimeDir}/audio_level`
        // Motoren skriver hvert 100 ms. Hurtigere er spildt arbejde -- der
        // staar ikke noget nyt i filen imellem.
        //
        // Og der laeses slet ikke naar der ikke optages: filen findes kun
        // undervejs, saa ellers ville vi vaekke disken ti gange i sekundet
        // doegnet rundt for at faa det samme ingenting.
        interval: root.active ? Config.voiceLevelInterval : 0

        onChanged: {
            if (!levelFile.exists) return;
            const raw = parseFloat(levelFile.text);
            if (!isNaN(raw)) root._smooth(root._shape(raw));
        }
    }

    // Naar filen forsvinder (optagelsen slut) skal boelgen falde til ro af sig
    // selv i stedet for at fryse i sidste udslag.
    Timer {
        interval: Config.voiceLevelInterval
        running: !levelFile.exists && root._level > 0
        repeat: true
        onTriggered: root._smooth(0)
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Al præsentation ét sted: pywal-paletten, runbar-tærskelrampen og de
// navngivne tilstandsfarver der før lå spredt i runbar-color.sh (pango-spans)
// og style.css (klasser). Bar, popup og OSD kan derfor ikke drifte fra hinanden.
Singleton {
    id: root

    // ---- pywal ------------------------------------------------------------
    // ~/.cache/wal/colors.json genskrives af ~/.Scripts/chwal. watchChanges
    // gør at farverne følger med uden USR2-signal, som waybar havde brug for.
    readonly property var _colors: wal.data.colors ?? ({})
    readonly property var _special: wal.data.special ?? ({})

    readonly property color background: _special.background ?? "#060701"
    readonly property color foreground: _special.foreground ?? "#a5a79c"

    readonly property color color0: _colors.color0 ?? "#060701"
    readonly property color color1: _colors.color1 ?? "#52474c"
    readonly property color color2: _colors.color2 ?? "#536b0b"
    readonly property color color3: _colors.color3 ?? "#a642b0"
    readonly property color color4: _colors.color4 ?? "#727b33"
    readonly property color color5: _colors.color5 ?? "#866c8f"
    readonly property color color6: _colors.color6 ?? "#8aa140"
    readonly property color color7: _colors.color7 ?? "#a5a79c"
    readonly property color color8: _colors.color8 ?? "#4b503a"

    // Baren er ugennemsigtig sort som alacritty/fuzzel — ikke wal-baggrunden.
    readonly property color barBackground: "#000000"

    // Kanten om pillerne. Hvid, og med vilje IKKE fra paletten — samme valg
    // som den sorte baggrund ovenfor. Paletten kan lande et hvilket som helst
    // sted (color4 blev rustroed, color7 graagroen), og kanten er det der
    // holder pillen sammen mod tapetet: den skal vaere lys hver gang, ikke
    // naesten-lys naar tapetet tillader det.
    //
    // Vinduernes kant er en anden ting og bliver ved med at vaere det: den
    // saar chwal fra wal ind i ~/.config/hypr/colors.lua. Det er kun
    // TYKKELSEN de to deler (Config.borderWidth = border_size).
    readonly property color pillBorder: "#ffffff"

    // ---- tilstandsfarver (var style.css-klasser) --------------------------
    readonly property color stateGood: "#0c0"   // .enabled, perf low-power
    readonly property color stateWarn: "#f80"   // .on (koffein), perf balanced
    readonly property color stateBusy: "#fa0"   // .processing (hyprwhspr wait)
    readonly property color stateBad: "#f00"    // .disabled, .recording, perf max

    // ---- afstande (var padding i style.css) -------------------------------
    readonly property int itemPadding: 8
    readonly property int workspacePadding: 6
    readonly property int workspaceActivePadding: 4
    // Maalt paa waybar: GTK-knappen har en mindstebredde paa indholdet, saa et
    // etcifret tal fylder lige saa meget som "10". Uden den her springer
    // resten af baren 8 px naar man skifter til workspace 10.
    readonly property int workspaceMinContent: 16
    readonly property int clockRightPadding: 10
    readonly property int underlineWidth: 2

    // ---- runbar-rampen ----------------------------------------------------
    // Portet 1:1 fra ~/.config/waybar/runbar-color.sh get_color, som selv
    // arvede den fra det gamle X11-runbar. Samme trin, samme hex-værdier.
    function rampColor(pct: real): color {
        if (pct <= 10) return "#f00";
        if (pct <= 25) return "#d50";
        if (pct <= 40) return "#c80";
        if (pct <= 55) return "#ba0";
        if (pct <= 70) return "#9b0";
        if (pct <= 85) return "#5b0";
        return "#0c0";
    }

    // runbar-color.sh wifi_color — dBm, ikke procent.
    function wifiColor(dbm: real): color {
        if (dbm <= -85) return "#f00";
        if (dbm <= -80) return "#d50";
        if (dbm <= -75) return "#c80";
        if (dbm <= -70) return "#ba0";
        if (dbm <= -65) return "#9b0";
        if (dbm <= -60) return "#5b0";
        return "#0c0";
    }

    JsonFile {
        id: wal
        file: `${Quickshell.env("HOME")}/.cache/wal/colors.json`
    }

    // chwal kalder den her naar paletten er skiftet, saa farverne foelger med
    // med det samme i stedet for ved naeste tjek.
    IpcHandler {
        target: "theme"
        function reload(): void { wal.reload(); }
    }
}

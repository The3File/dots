pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services

// Volumen kommer direkte fra Pipewire i stedet for at spoerge pamixer hvert
// femte sekund. Det er derfor RTMIN+1-signalerne i hyprland.lua,
// low_battery_warning, btcon og pwrbtnlght kan blive staaende urestaurerede:
// der er ingen der skal vaekkes laengere.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready

    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool bluetooth: String(sink?.name ?? "").startsWith("bluez_output")

    // runbar-color.sh vol: "bth" naar default sink er bluetooth, ellers "vol";
    // mutet vises i parentes og med rampens bundfarve.
    readonly property string label: bluetooth ? "bth" : "vol"
    readonly property color valueColor: {
        if (muted) return Theme.rampColor(0);
        if (percent > 100) return Theme.stateBad;
        return Theme.rampColor(percent);
    }
    readonly property string text:
        `${label}: ` + Markup.colored(muted ? `(${percent}%)` : `${percent}%`, valueColor)

    readonly property bool visible: ready
    readonly property color color: Theme.foreground
    readonly property bool underline: false
    readonly property string tooltip: ""

    function toggleMute(): void {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    // Uden en tracker holder Pipewire ikke noden aaben, og audio-feltet er tomt.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
}

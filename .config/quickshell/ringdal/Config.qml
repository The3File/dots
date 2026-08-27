pragma Singleton

import Quickshell
import Quickshell.Io
import qs.services

// Brugerens skruer, læst fra config.json ved siden af. watchChanges betyder at
// en rettelse i JSON-filen slår igennem med det samme — ingen genstart, ingen QML.
// Værdierne her i QML er defaults; JSON'en overskriver kun det den nævner.
Singleton {
    id: root

    readonly property var _bar: file.data.bar ?? ({})
    readonly property var _intervals: file.data.intervals ?? ({})
    readonly property var _font: _bar.font ?? ({})

    readonly property int barHeight: _bar.height ?? 26
    // Tom liste = bar på alle skærme. Ellers fx ["eDP-1"].
    readonly property var barScreens: _bar.screens ?? []

    readonly property string fontFamily: _font.family ?? "Terminus"
    readonly property int fontSize: _font.size ?? 14

    readonly property int whsprInterval: _intervals.whspr ?? 1000
    readonly property int perfInterval: _intervals.perf ?? 2000
    readonly property int keylockInterval: _intervals.keylock ?? 5000
    readonly property int netInterval: _intervals.net ?? 5000
    readonly property int backlightInterval: _intervals.backlight ?? 5000
    readonly property int koffeinInterval: _intervals.koffein ?? 30000
    readonly property int clockInterval: _intervals.clock ?? 30000

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: `${home}/.Scripts`

    function wantsScreen(screen): bool {
        return barScreens.length === 0 || barScreens.indexOf(screen.name) >= 0;
    }

    JsonFile {
        id: file
        file: `${Quickshell.env("HOME")}/.config/quickshell/ringdal/config.json`
        // Den her rettes i haanden, saa den maa gerne tjekkes lidt oftere.
        interval: 2000
    }

    IpcHandler {
        target: "config"
        function reload(): void { file.reload(); }
    }
}

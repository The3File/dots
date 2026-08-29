pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

// Sysfs sender ikke paalidelige aendringsbeskeder, saa lysstyrken maa hentes.
// Men den bliver ikke hentet i baggrunden: lystasterne i hyprland.lua kalder
// `qs ipc call backlight refresh`, og kigget kalder refresh() naar det folder
// sig ud. Det er de eneste to steder tallet nogensinde ses.
//
// Config.backlightInterval staar paa 0 = intet poll. Saet den til et tal igen,
// hvis der nogensinde kommer en flade, der viser lysstyrken hele tiden.
Singleton {
    id: root

    property int percent: 0
    readonly property bool visible: true

    readonly property string text:
        "scrn: " + Markup.colored(`${percent}%`, Theme.rampColor(percent))

    readonly property color color: Theme.foreground
    readonly property bool underline: false
    readonly property string tooltip: ""

    function refresh(): void {
        if (!proc.running) proc.running = true;
    }

    Process {
        id: proc
        // `light -G` giver procent som decimaltal; waybar regnede
        // cur*100/max i heltal, og heltalsdivision skaerer nedad.
        command: ["light", "-G"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(this.text);
                if (!isNaN(v)) root.percent = Math.floor(v);
            }
        }
    }

    // Gotcha: en QML-Timer med interval 0 fyrer i ét vaek. Derfor skal
    // running haenge paa tallet, ikke staa paa true -- ellers bliver "sluk
    // pollet" til "poll saa hurtigt maskinen kan".
    Timer {
        interval: Config.backlightInterval
        running: Config.backlightInterval > 0
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "backlight"
        function refresh(): void { root.refresh(); }
    }
}

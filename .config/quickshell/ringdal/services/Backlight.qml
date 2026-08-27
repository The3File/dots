pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

// Sysfs sender ikke paalidelige aendringsbeskeder, saa lysstyrken hentes med
// et lille poll -- men lystasterne i hyprland.lua kalder ogsaa
// `qs ipc call backlight refresh`, saa den foelger med med det samme naar det
// er dig der skruer. Pollet er kun sikkerhedsnettet.
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

    Timer {
        interval: Config.backlightInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "backlight"
        function refresh(): void { root.refresh(); }
    }
}

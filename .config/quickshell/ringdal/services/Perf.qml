pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// ~/.Scripts/perf-mode bliver liggende som selvstaendig kommando -- den er
// nyttig fra terminalen, og waybar-fallbacken bruger den stadig.
Singleton {
    id: root

    readonly property string text: Markup.esc(svc.text)
    readonly property string tooltip: svc.tooltip
    readonly property bool visible: svc.visible
    readonly property string mode: svc.cls

    readonly property color color: {
        switch (svc.cls) {
        case "low-power": return Theme.stateGood;
        case "balanced": return Theme.stateWarn;
        case "performance": return Theme.stateBad;
        case "boost": return Theme.stateBad;
        default: return Theme.foreground;
        }
    }
    // style.css gav kun boost en understregning.
    readonly property bool underline: svc.cls === "boost"

    function openMenu(): void { svc.run([`${Config.scripts}/perf-mode`, "menu"]); }

    ScriptService {
        id: svc
        command: [`${Config.scripts}/perf-mode`, "status"]
        interval: Config.perfInterval
        ipcTarget: "perf"
    }
}

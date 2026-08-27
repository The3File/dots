pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Vises kun naar den er taendt -- scriptet sender tom tekst naar den er
// slukket, og tom tekst betyder skjult modul.
Singleton {
    id: root

    readonly property string text: Markup.esc(svc.text)
    readonly property string tooltip: svc.tooltip
    readonly property bool visible: svc.visible
    readonly property bool on: svc.cls === "on"

    readonly property color color: on ? Theme.stateWarn : Theme.foreground
    readonly property bool underline: false

    function turnOff(): void { svc.run([`${Config.scripts}/koffein`, "off"]); }

    ScriptService {
        id: svc
        command: [`${Config.scripts}/koffein`, "status"]
        interval: Config.koffeinInterval
        ipcTarget: "koffein"
    }
}

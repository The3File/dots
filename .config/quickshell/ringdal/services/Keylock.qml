pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Tastaturlaasen er en noedudgang: den skal kunne slaas til og fra af
// ACPI-tasten selv naar shellen ikke koerer. Derfor bliver ~/.Scripts/lock_keys
// ved med at vaere den der ejer tilstanden -- vi kigger kun med.
Singleton {
    id: root

    readonly property string text: Markup.esc(svc.text)
    readonly property string tooltip: svc.tooltip
    readonly property bool visible: svc.visible
    readonly property bool locked: svc.cls === "disabled"

    readonly property color color: {
        if (svc.cls === "enabled") return Theme.stateGood;
        if (svc.cls === "disabled") return Theme.stateBad;
        return Theme.foreground;
    }
    readonly property bool underline: false

    function toggle(): void { svc.run([`${Config.scripts}/lock_keys`, "toggle"]); }

    ScriptService {
        id: svc
        command: [`${Config.scripts}/lock_keys`, "status"]
        interval: Config.keylockInterval
        ipcTarget: "keylock"
    }
}

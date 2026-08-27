pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Diktering. Statusscriptet ligger hos waybar-configen i dag; det flytter med
// ind under quickshell ved cutover, saa begge peger paa samme fil indtil da.
Singleton {
    id: root

    readonly property string statusScript:
        `${Config.home}/.config/waybar/hyprwhspr-status.sh`
    readonly property string trayScript:
        "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh"

    readonly property string text: Markup.esc(svc.text)
    readonly property string tooltip: svc.tooltip
    readonly property bool visible: svc.visible
    readonly property bool recording: svc.cls === "recording"
    readonly property bool processing: svc.cls === "processing"

    readonly property color color: {
        switch (svc.cls) {
        case "recording": return Theme.stateBad;
        case "processing": return Theme.stateBusy;
        case "error": return Theme.stateBad;
        default: return Theme.color8;
        }
    }
    readonly property bool underline: recording || processing

    function toggleRecord(): void { svc.run([root.trayScript, "record"]); }
    function toggleOverlay(): void {
        svc.run([`${Config.scripts}/hyprwhspr-ui`, "overlay", "toggle"]);
    }

    ScriptService {
        id: svc
        command: [root.statusScript]
        interval: Config.whsprInterval
        ipcTarget: "whspr"
    }
}

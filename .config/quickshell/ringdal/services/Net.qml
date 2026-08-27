pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// runbar-color.sh laver iw/ip-parsingen; den er ikke vaerd at skrive om i QML.
// Men dens pango bliver oversat her, saa ingen widget nogensinde ser markup
// fra et script.
//
// Senere: Quickshell.Networking har en rigtig NetworkManager-service. Den
// giver signalstyrke i procent, ikke dBm, saa den venter til vi alligevel
// bygger netvaerksmenuen -- indtil da ville den aendre det baren viser.
Singleton {
    id: root

    readonly property string text: Markup.fromPango(svc.text)
    readonly property bool visible: svc.visible
    readonly property bool connected: svc.text.indexOf("no connection") < 0

    readonly property color color: Theme.foreground
    readonly property bool underline: false
    // Scriptet farver selv dBm-tallet; resten er almindelig forgrund.
    readonly property string tooltip: ""

    function openPicker(): void { svc.run([`${Config.scripts}/fuzzel_nm`]); }

    ScriptService {
        id: svc
        command: [`${Config.home}/.config/waybar/runbar-color.sh`, "net"]
        interval: Config.netInterval
    }
}

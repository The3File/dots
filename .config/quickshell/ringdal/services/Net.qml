pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// ~/.Scripts/netstatus laver iw/ip-parsingen; den er ikke vaerd at skrive om i
// QML. Men dens pango bliver oversat her, saa ingen widget nogensinde ser
// markup fra et script.
//
// Den ENESTE ting svaret bruges til er "intet net" i afvigelses-pillen. Derfor
// spoerges der hvert 15. sekund og ikke hvert 5.: det er en afvigelse, ikke en
// aflaesning, og et kvarter-minut er hurtigt nok til at opdage at nettet er
// vaek.
//
// Senere: Quickshell.Networking (som Wifi bruger) har ogsaa et svar. Men den
// ser kun wifi, og netstatus ser ogsaa kablet. Skiftet kraever at
// Networking.connectivity er proevet af med kablet i -- indtil da bliver den
// her.
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
        command: [`${Config.scripts}/netstatus`]
        interval: Config.netInterval
    }
}

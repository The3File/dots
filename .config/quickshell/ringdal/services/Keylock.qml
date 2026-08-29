pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Tastaturlaasen er en noedudgang: den skal kunne slaas til og fra af
// ACPI-tasten selv naar shellen ikke koerer. Derfor bliver ~/.Scripts/lock_keys
// ved med at vaere den der ejer tilstanden -- vi kigger kun med.
//
// Vi kigger med paa FILEN, ikke gennem scriptet. Flaget ~/.keylock er allerede
// kilden til sandhed for lock_keys selv, og en fil kan overvaages gratis.
// Foer stod pillen og koerte `lock_keys status` hvert femte sekund -- 48 ms
// hver gang, 12 gange i minuttet, for at faa at vide at alt var som det plejer.
//
// Scriptet koeres stadig, men kun mens laasen er slaaet TIL, og det er ikke
// for at laese noget: `status` saetter enhederne fra igen, hvis en
// hyprctl-genindlaesning har vaekket dem. Den reparation skal blive ved med at
// findes -- men den er kun noget vaerd i den ene tilstand, hvor den betyder
// noget, og den tilstand er den sjaeldne.
Singleton {
    id: root

    // Flaget staar foer scriptet: skiftet skal ses med det samme, ikke naar
    // naeste tik tilfaeldigvis rammer.
    readonly property bool locked: flag.text.trim() === "disable"

    readonly property string text: `kbd: ${root.locked ? "disabled" : "enabled"}`
    readonly property string tooltip: svc.tooltip
    readonly property bool visible: true

    readonly property color color: root.locked ? Theme.stateBad : Theme.stateGood
    readonly property bool underline: false

    function toggle(): void { svc.run([`${Config.scripts}/lock_keys`, "toggle"]); }

    TextFile {
        id: flag
        file: `${Config.home}/.keylock`
        // 0 = ingen genlaesning paa tid. FileView holder oeje med filen selv.
        interval: 0
    }

    ScriptService {
        id: svc
        command: [`${Config.scripts}/lock_keys`, "status"]
        // Kun mens der er laast. 0 = slukket.
        interval: root.locked ? Config.keylockInterval : 0
        ipcTarget: "keylock"
    }
}

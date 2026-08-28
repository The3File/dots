pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.services

// Var `date '+%a %d %b %H%M' | tr '[:upper:]' '[:lower:]'` i en proces hvert
// halve minut. Locale er C.UTF-8, saa Qt's standardlocale giver de samme
// engelske forkortelser -- ingen proces noedvendig.
Singleton {
    id: root

    readonly property string text:
        Markup.esc(Qt.formatDateTime(clock.date, "ddd dd MMM HHmm").toLowerCase())

    // Kort form til den simplificerede krop. Datoen er der stadig, den
    // staar bare ikke fremme laengere.
    readonly property string shortText:
        Qt.formatDateTime(clock.date, "HH:mm")

    readonly property bool visible: true
    readonly property color color: Theme.foreground
    readonly property bool underline: false
    readonly property string tooltip: ""

    function openCalendar(): void {
        Quickshell.execDetached([
            "alacritty", "--class", "cal", "-e",
            "bash", "-c", "cal -mw; read -rsn1"
        ]);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

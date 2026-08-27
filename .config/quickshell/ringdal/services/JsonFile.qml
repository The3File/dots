import QtQuick
import Quickshell
import Quickshell.Io

// Laeser en JSON-fil og holder oeje med om den aendrer sig.
//
// FileViews egen watchChanges kan ikke staa alene: den sender kun en besked om
// at filen er aendret (ikke det nye indhold), den overlever ikke at en editor
// eller et script bytter filen ud i stedet for at skrive i den, og den holder
// op med at sige til efter foerste gang. Derfor genlaeses filen ogsaa med et
// roligt interval, og der publiceres kun naar indholdet rent faktisk er et
// andet -- ellers ville bindingerne blafre ved hver genlaesning.
//
// Kilder der ved hvornaar de har aendret filen (fx chwal) kan kalde reload()
// over IPC og faa svaret med det samme i stedet for at vente paa naeste tjek.
Scope {
    id: root

    required property string file
    // Hvor tit filen genlaeses som sikkerhedsnet. 0 slaar det fra.
    property int interval: 5000

    readonly property var data: _data
    readonly property bool loaded: _loaded

    property var _data: ({})
    property string _raw: ""
    property bool _loaded: false

    signal changed()

    function reload(): void {
        // At saette stien forfra er det eneste der faar FileView til at laese
        // igen -- og det genarmerer samtidig overvaagningen efter et filbytte.
        view.path = "";
        view.path = root.file;
    }

    FileView {
        id: view
        path: root.file
        watchChanges: true
        preload: true

        onFileChanged: root.reload()
        onLoaded: {
            const raw = view.text();
            if (raw === root._raw) return;
            root._raw = raw;
            try {
                root._data = JSON.parse(raw);
                root._loaded = true;
                root.changed();
            } catch (e) {
                console.warn(`JsonFile: kunne ikke laese ${root.file}:`, e);
            }
        }
    }

    Timer {
        interval: root.interval
        running: root.interval > 0
        repeat: true
        onTriggered: root.reload()
    }
}

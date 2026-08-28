import QtQuick
import Quickshell
import Quickshell.Io

// Som JsonFile, men for rene tekstfiler -- og med den forskel at filen her
// har lov til ikke at findes.
//
// hyprwhspr sletter audio_level naar der ikke optages, saa "filen mangler" er
// en normal tilstand og ikke en fejl. exists fortaeller hvad der er tilfaeldet;
// text er tom naar filen er vaek.
Scope {
    id: root

    required property string file
    // Hvor tit filen genlaeses. 0 slaar det fra.
    property int interval: 1000

    readonly property string text: _text
    readonly property bool exists: _exists

    property string _text: ""
    property bool _exists: false

    signal changed()

    function reload(): void {
        // Samme kneb som i JsonFile: kun en ny sti faar FileView til at laese
        // igen, og det genarmerer overvaagningen efter et filbytte.
        view.path = "";
        view.path = root.file;
    }

    function _publish(raw: string, exists: bool): void {
        if (raw === root._text && exists === root._exists) return;
        root._text = raw;
        root._exists = exists;
        root.changed();
    }

    FileView {
        id: view
        path: root.file
        watchChanges: true
        preload: true
        // Den manglende fil er hviletilstanden her, ikke en fejl. Uden
        // det her skriver den i loggen ti gange i sekundet doegnet rundt.
        printErrors: false

        onFileChanged: root.reload()
        onLoaded: root._publish(view.text(), true)
        // Ingen advarsel her -- den manglende fil er den normale hviletilstand.
        onLoadFailed: root._publish("", false)
    }

    Timer {
        interval: root.interval
        running: root.interval > 0
        repeat: true
        onTriggered: root.reload()
    }
}

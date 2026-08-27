import QtQuick
import Quickshell
import Quickshell.Io

// Fælles motor for de moduler der stadig henter deres tilstand fra et script i
// ~/.Scripts. Scriptet er kilden til data og handlinger; præsentationen ejes af
// Theme. Servicen kender ikke til noget visuelt.
//
// Scriptene taler waybars JSON — {"text","class","tooltip"} — fordi de skal
// blive ved med at virke med waybar som fallback. Oversættelsen til typede
// egenskaber sker her, ét sted, i stedet for ude i hver widget.
Scope {
    id: root

    // Kommandoen der spørger om status.
    property list<string> command: []
    // Hvor tit der spørges, i millisekunder.
    property int interval: 5000
    // Navn til `qs ipc call <target> refresh`. Tomt = ingen IPC.
    property string ipcTarget: ""

    readonly property string text: _text
    readonly property string cls: _cls
    readonly property string tooltip: _tooltip
    // Tomt text betyder skjult modul — sådan gemmer koffein sig i dag.
    readonly property bool visible: _text !== ""
    readonly property bool ok: _ok

    property string _text: ""
    property string _cls: ""
    property string _tooltip: ""
    property bool _ok: false

    signal updated()

    function refresh(): void {
        if (!proc.running) proc.running = true;
    }

    // Kør en handling (klik) og hent straks ny status, så baren ikke venter
    // på næste tik.
    function run(cmd: list<string>): void {
        Quickshell.execDetached(cmd);
        settle.restart();
    }

    Process {
        id: proc
        command: root.command
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    Timer {
        interval: root.interval
        running: root.interval > 0
        repeat: true
        onTriggered: root.refresh()
    }

    // Efter et klik: giv scriptet et øjeblik til at nå at ændre tilstand.
    Timer {
        id: settle
        interval: 150
        repeat: false
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: root.ipcTarget
        enabled: root.ipcTarget !== ""
        function refresh(): void { root.refresh(); }
    }

    function _parse(raw: string): void {
        const trimmed = (raw ?? "").trim();
        if (trimmed === "") { root._ok = false; return; }

        let data;
        try {
            data = JSON.parse(trimmed);
        } catch (e) {
            root._ok = false;
            console.warn(`ScriptService(${root.ipcTarget}): kunne ikke læse JSON:`, trimmed.slice(0, 120));
            return;
        }

        root._text = data.text ?? "";
        root._cls = data.class ?? "";
        // hyprwhspr-tray.sh hænger et usynligt _ts: på tooltippen for at tvinge
        // waybar til at gentegne. Vi har ikke brug for det — og det skal ikke
        // stå i en popup.
        root._tooltip = String(data.tooltip ?? "")
            .split("\n")
            .filter(line => !line.startsWith("_ts:"))
            .join("\n")
            .trim();
        root._ok = true;
        root.updated();
    }
}

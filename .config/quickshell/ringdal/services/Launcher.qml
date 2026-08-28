pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Applikationsaabneren. Afloeser fuzzel_drun.
//
// Den er ikke et vindue for sig. Den er en tilstand i pillen -- samme krop,
// vokset op til at kunne skrives i. Det er hele pointen med at have én form:
// naar man trykker Super+D, er det pillen der aabner sig, ikke et fremmed
// program der lander oven paa skaermen.
//
// Rangordenen er substring som i fuzzel, men med hukommelse: det man aabner
// tit, ligger oeverst. Uden det skal man skrive hele navnet paa den samme
// browser ti gange om dagen.
Singleton {
    id: root

    property bool active: false
    property string query: ""
    property int index: 0

    // id -> hvornaar den sidst blev startet. Ligger i cache og ikke i
    // config.json: det er noget maskinen laerer, ikke noget Filip skruer paa.
    property var recent: ({})

    readonly property var apps: DesktopEntries.applications.values
    readonly property var results: root._rank(root.query, root.apps, root.recent)

    readonly property var selected:
        root.index >= 0 && root.index < root.results.length
            ? root.results[root.index] : null

    function open(): void {
        root.query = "";
        root.index = 0;
        root.active = true;
    }

    function close(): void {
        root.active = false;
        root.query = "";
        root.index = 0;
    }

    function toggle(): void {
        if (root.active) root.close(); else root.open();
    }

    function move(delta: int): void {
        const n = root.results.length;
        if (n === 0) return;
        root.index = (root.index + delta + n) % n;
    }

    function run(): void {
        root.launch(root.selected);
    }

    function launch(entry): bool {
        if (!entry) return false;
        root._remember(entry.id);
        // Luk foerst. Ellers staar aabneren og holder tastaturet mens det
        // nye vindue forsoeger at komme frem.
        root.close();
        entry.execute();
        return true;
    }

    // ---- rangordning ------------------------------------------------------
    function _hits(list, needle: string): bool {
        if (!list) return false;
        for (const item of list) {
            if ((item ?? "").toLowerCase().indexOf(needle) >= 0) return true;
        }
        return false;
    }

    function _rank(q, apps, recent) {
        const needle = (q ?? "").trim().toLowerCase();
        const rows = [];

        for (const app of (apps ?? [])) {
            if (!app || app.noDisplay) continue;

            const name = (app.name ?? "").toLowerCase();
            let score;

            if (needle === "") score = 1;
            else if (name.startsWith(needle)) score = 4;
            else if (name.indexOf(needle) >= 0) score = 3;
            else if ((app.genericName ?? "").toLowerCase().indexOf(needle) >= 0) score = 2;
            else if (root._hits(app.keywords, needle)) score = 1;
            else continue;

            rows.push({
                entry: app,
                score: score,
                used: recent[app.id] ?? 0,
                name: name
            });
        }

        rows.sort((a, b) =>
            b.score - a.score
            || b.used - a.used
            || (a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)));

        return rows.slice(0, Config.launchLines).map(r => r.entry);
    }

    function _remember(id: string): void {
        const next = Object.assign({}, root.recent);
        next[id] = Date.now();
        root.recent = next;
        store.setText(JSON.stringify(next));
    }

    // Filen findes ikke foerste gang. Det er ikke en fejl, det er en tom
    // hukommelse.
    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.cache/quickshell-launcher.json`
        preload: true
        printErrors: false
        atomicWrites: true

        onLoaded: {
            try {
                root.recent = JSON.parse(store.text()) ?? ({});
            } catch (e) {
                root.recent = ({});
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }

        // Aabn med noget skrevet i forvejen -- til naar Filip siger hvad han
        // vil have frem, men selv vil vaelge i listen.
        function search(text: string): void {
            root.open();
            root.query = text;
            root.index = 0;
        }

        // Start noget direkte. Samme rangordning som i listen, saa "brave"
        // rammer det samme som at skrive "brave" og trykke retur.
        function start(name: string): string {
            const hits = root._rank(name, root.apps, root.recent);
            if (hits.length === 0) return `fandt ikke: ${name}`;
            root.launch(hits[0]);
            return hits[0].name;
        }

        function state(): string { return root.active ? "open" : "closed"; }

        function list(): string {
            return root.results.map(e => e.name).join("\n");
        }
    }
}

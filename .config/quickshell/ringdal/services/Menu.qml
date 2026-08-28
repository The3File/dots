pragma Singleton

import QtQuick
import Quickshell
import qs

// Menuens motor. Kender ingenting til wifi eller bluetooth -- den holder bare
// styr paa hvor man er, hvad der staar paa listen, og hvad tastaturet peger paa.
//
// Det er den samme model fuzzel havde: en liste, et filter man skriver i, og
// piletaster. Grunden til at den er skilt ud er, at hver eneste flade i pillen
// saa opfoerer sig ens -- man skal ikke laere en ny maade at gaa tilbage paa,
// fordi man er i bluetooth i stedet for wifi.
//
// En side er { title, load } hvor load() henter og kalder fill(). Sider kan
// vaere langsomme (et scan tager sekunder), saa listen fyldes bagefter, ikke
// paa stedet.
Singleton {
    id: root

    property var stack: []
    property var items: []
    property string query: ""
    property int index: 0
    // Bliver sat mens noget koerer, saa fladen kan sige hvorfor den er tom.
    property string status: ""

    // Et svar der skal skrives, fx en wifi-adgangskode:
    // { title, masked, submit(text) }. Er den sat, viser fladen et felt i
    // stedet for en liste.
    property var prompt: null

    readonly property bool active: root.stack.length > 0
    readonly property bool nested: root.stack.length > 1
    readonly property string title: root.active ? root.stack[root.stack.length - 1].title : ""

    readonly property var view: root._filter(root.items, root.query)
    readonly property var current:
        root.index >= 0 && root.index < root.view.length ? root.view[root.index] : null

    signal closed()

    function open(page): void {
        root.stack = [page];
        root._enter();
    }

    // Aabn direkte paa et underlag, med roden bagved. Saa virker "tilbage"
    // ogsaa naar man kom ind udefra i stedet for gennem roden.
    function open2(base, page): void {
        root.stack = [base, page];
        root._enter();
    }

    function push(page): void {
        root.stack = root.stack.concat([page]);
        root._enter();
    }

    // Ét lag tilbage. Er der ikke flere lag, er vi ude.
    function back(): void {
        if (root.prompt !== null) { root.prompt = null; return; }
        if (root.stack.length <= 1) { root.close(); return; }
        root.stack = root.stack.slice(0, -1);
        root._enter();
    }

    function close(): void {
        root.stack = [];
        root.items = [];
        root.query = "";
        root.index = 0;
        root.status = "";
        root.prompt = null;
        root.closed();
    }

    // Samme side, nye tal. Filteret bliver staaende -- man har lige skrevet
    // det, og en handling maa ikke tage det fra én.
    function refresh(): void {
        if (!root.active) return;
        root.status = "henter...";
        root.stack[root.stack.length - 1].load();
    }

    function fill(list): void {
        root.items = list ?? [];
        root.status = "";
        if (root.index >= root.view.length) root.index = 0;
    }

    function ask(title: string, masked: bool, submit): void {
        root.prompt = { title: title, masked: masked, submit: submit };
    }

    function answer(text: string): void {
        const p = root.prompt;
        root.prompt = null;
        if (p && p.submit) p.submit(text);
    }

    function move(delta: int): void {
        const n = root.view.length;
        if (n === 0) return;
        root.index = (root.index + delta + n) % n;
    }

    function select(item): void {
        const i = root.view.indexOf(item);
        if (i >= 0) root.index = i;
    }

    // Vaelg en linje ved navn. Det er den vej udefra: Claude kan laese
    // listen og trykke paa en linje, praecis som Filip kan.
    function pick(label: string): bool {
        const needle = (label ?? "").trim().toLowerCase();
        if (needle === "") return false;
        const hit = root.items.find(i =>
            (i.label ?? "").toLowerCase().indexOf(needle) >= 0);
        if (!hit) return false;
        root.activate(hit);
        return true;
    }

    function labels(): var {
        return root.items.map(i => i.label ?? "");
    }

    function activate(item): void {
        const it = item ?? root.current;
        if (it && it.run) it.run();
    }

    function _enter(): void {
        root.query = "";
        root.index = 0;
        root.items = [];
        root.prompt = null;
        root.status = "henter...";
        root.stack[root.stack.length - 1].load();
    }

    function _filter(items, q) {
        const needle = (q ?? "").trim().toLowerCase();
        if (needle === "") return items ?? [];
        return (items ?? []).filter(i =>
            (i.label ?? "").toLowerCase().indexOf(needle) >= 0
            || (i.hint ?? "").toLowerCase().indexOf(needle) >= 0);
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs

// Beskederne. Afloeser dunst.
//
// To ting, ikke én: der er *det der lige skete*, og der er *det der stadig
// venter*. Dunst blandede dem sammen -- en boble der forsvinder af sig selv,
// og saa er beskeden vaek uanset om du saa den.
//
// Her kommer beskeden frem i pillen et oejeblik og traekker sig igen, men den
// bliver liggende i listen til den er lukket. Er der noget tilbage, staar det
// i afvigelses-pillen. Er der ingenting, staar der ingenting -- samme regel
// som resten af shellen.
//
// Kritiske beskeder traekker sig ikke selv. De er den ene slags der har lov
// at blive staaende.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    readonly property int count: root.list.length

    property var latest: null
    property bool popup: false
    // Listen staar aaben. Den bor i output-pillen ved siden af kroppen, saa
    // det han selv er i gang med, ikke bliver skubbet vaek af noget han bare
    // ville kigge paa.
    property bool listing: false
    // Musen paa beskeden holder den. Man skal kunne naa at laese noget man
    // er i gang med at laese.
    property bool held: false

    readonly property bool critical:
        root.latest !== null
        && root.latest.urgency === NotificationUrgency.Critical

    function hide(): void {
        linger.stop();
        root.popup = false;
    }

    // Boblen viger for listen: er der ingenting at vise, aabnes der ingenting
    // -- en tom flade er vaerre end ingen flade. Svaret siger hvad der skete,
    // saa den der kaldte, kan sige det videre.
    function openList(): bool {
        if (root.count === 0) return false;
        root.hide();
        root.listing = true;
        return true;
    }

    function closeList(): void {
        // Musen kan naa at forlade listen ved at listen forsvinder under den,
        // og saa kommer der ingen exited. Uden det her blev `held` haengende
        // og holdt den naeste boble staaende for evigt.
        root.held = false;
        root.listing = false;
    }

    function toggleList(): bool {
        if (root.listing) { root.closeList(); return false; }
        return root.openList();
    }

    // Sidste besked lukket = ingenting tilbage at staa og se paa. Listen
    // lukker sig selv i stedet for at blive haengende som en tom pille.
    onCountChanged: if (root.count === 0) root.closeList();

    function dismiss(n): void {
        if (!n) return;
        if (n === root.latest) root.hide();
        n.dismiss();
    }

    function clear(): void {
        root.hide();
        // Baglaens: listen kortes af mens vi gaar igennem den.
        const all = root.list.slice();
        for (let i = all.length - 1; i >= 0; i--) all[i].dismiss();
        root.latest = null;
    }

    // Foerste knap paa beskeden, hvis der er en. Ellers luk den bare.
    function act(n): void {
        if (!n) return;
        if (n.actions && n.actions.length > 0) {
            n.actions[0].invoke();
            return;
        }
        root.dismiss(n);
    }

    function _show(n): void {
        root.latest = n;
        // Ligger listen aaben, staar beskeden der allerede. En boble oven paa
        // ville daekke det han sidder og laeser.
        if (root.listing) return;
        root.popup = true;
        if (n.urgency === NotificationUrgency.Critical) linger.stop();
        else linger.restart();
    }

    NotificationServer {
        id: server

        // Vi holder selv paa beskederne, saa afsenderen ikke lader dem
        // udloebe bag om ryggen paa listen.
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root._show(n);
            root._trim();
        }
    }

    // Listen er en historik, ikke et arkiv. Bliver den lang, ryger det
    // aeldste -- ellers er den ikke til at bruge til noget.
    function _trim(): void {
        const all = root.list;
        const over = all.length - Config.notifyMax;
        for (let i = 0; i < over; i++) all[i].dismiss();
    }

    Timer {
        id: linger
        interval: Config.notifyLinger
        repeat: false
        onTriggered: {
            if (root.held) { linger.restart(); return; }
            root.popup = false;
            // "transient" betyder at afsenderen selv siger at beskeden ikke er
            // vaerd at gemme (statuslinjer, fremdrift). Den skal ikke ligge og
            // fylde i listen bagefter.
            if (root.latest && root.latest.transient) root.latest.dismiss();
        }
    }

    IpcHandler {
        target: "notifs"

        function count(): string { return `${root.count}`; }
        function hide(): void { root.hide(); }
        function clear(): void { root.clear(); }

        // Listen skal kunne aabnes og lukkes udefra som alt andet i pillen.
        function open(): string {
            return root.openList() ? "aabnede listen" : "ingen beskeder";
        }
        function close(): void { root.closeList(); }
        function toggle(): string {
            return root.toggleList() ? "aabnede listen"
                : (root.count === 0 ? "ingen beskeder" : "lukkede listen");
        }

        // Saa Claude kan se hvad der ligger og venter uden at Filip skal
        // laese det op.
        function list(): string {
            if (root.count === 0) return "ingen beskeder";
            return root.list.map(n =>
                `${n.appName}: ${n.summary}${n.body ? " -- " + n.body : ""}`
            ).join("\n");
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs
import qs.services

// Netvaerk fra NetworkManager direkte. Afloeser runbar-color.sh's iw-parsing
// for alt undtagen selve bar-teksten, som stadig ligger i Net.qml indtil den
// ikke bruges laengere.
//
// Signalstyrken kommer som 0-1 fra NM-laget, men det er ikke garanteret paa
// tvaers af versioner -- derfor normaliseres den ét sted her, saa ingen widget
// skal gaette.
Singleton {
    id: root

    readonly property var device: {
        const list = Networking.devices?.values ?? [];
        for (const d of list) {
            if (d.type === DeviceType.Wifi) return d;
        }
        return null;
    }

    readonly property bool available: device !== null
    readonly property bool enabled: Networking.wifiEnabled

    // Forbundet, saa kendte, saa efter styrke. Det man leder efter staar
    // oeverst; resten er en liste man scanner.
    readonly property var networks: {
        const list = device?.networks?.values ?? [];
        const copy = list.slice();
        copy.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return root.strengthOf(b) - root.strengthOf(a);
        });
        return copy;
    }

    readonly property var current: {
        const list = device?.networks?.values ?? [];
        for (const n of list) if (n.connected) return n;
        return null;
    }

    readonly property bool connected: current !== null
    readonly property string ssid: current?.name ?? ""
    readonly property int strength: current ? strengthOf(current) : 0

    // NetworkManager scanner ikke af sig selv. Uden det her ser listen kun
    // det net man allerede er paa -- hvilket var praecis det den gjorde foerst.
    // Scanneren koerer kun mens menuen er aaben; den koster stroem.
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: Pill.opened
        when: root.device !== null
    }

    function strengthOf(network): int {
        const raw = network?.signalStrength ?? 0;
        return Math.round(raw <= 1 ? raw * 100 : raw);
    }

    function secured(network): bool {
        return network?.security !== undefined
            && network.security !== WifiSecurityType.Open;
    }

    // Kendte net kan forbindes uden at spoerge om noget. Ukendte kraever en
    // adgangskode, og den kan pillen ikke tage imod endnu -- derfor sendes de
    // videre til den vaelger der allerede virker.
    function activate(network): void {
        if (!network) return;
        if (network.connected) return;
        if (network.known && network.nmSettings && network.nmSettings.length > 0) {
            network.connect(network.nmSettings[0]);
        } else {
            Quickshell.execDetached([`${Config.scripts}/fuzzel_nm`]);
        }
    }
}

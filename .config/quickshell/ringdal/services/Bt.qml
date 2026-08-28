pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth fra BlueZ direkte. `connected` er skrivbar, saa forbind og afbryd
// er en tilskrivning -- ingen proces.
//
// btcon bliver staaende som kommando, og dens huskeliste over enheder BlueZ har
// glemt, er stadig dens. Her vises kun det BlueZ selv kender.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool scanning: adapter?.discovering ?? false

    // Forbundne foerst, saa parrede, saa resten alfabetisk.
    readonly property var devices: {
        const list = adapter?.devices?.values ?? [];
        const copy = list.slice();
        copy.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return String(a.name ?? "").localeCompare(String(b.name ?? ""));
        });
        return copy;
    }

    readonly property var connectedDevices: {
        const list = adapter?.devices?.values ?? [];
        return list.filter(d => d.connected);
    }

    readonly property bool anyConnected: connectedDevices.length > 0

    function label(device): string {
        const name = String(device?.deviceName || device?.name || "?");
        if (device?.batteryAvailable) {
            const pct = Math.round((device.battery ?? 0) * 100);
            return `${name} ${pct}%`;
        }
        return name;
    }

    function toggle(device): void {
        if (!device) return;
        device.connected = !device.connected;
    }

    function scan(): void {
        if (adapter) adapter.discovering = !adapter.discovering;
    }
}

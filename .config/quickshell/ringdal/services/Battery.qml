pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services

// UPower i stedet for at laese /sys hvert halve minut. Teksten holdes ordret
// paa waybars form: statusordet fra sysfs med smaa bogstaver, saa "discharging:
// 78%" bliver ved med at vaere "discharging: 78%".
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool ready: device !== null && device.ready && device.isPresent

    // UPower giver 0-1, ikke 0-100.
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)

    readonly property string statusText: {
        switch (device?.state) {
        case UPowerDeviceState.Charging: return "charging";
        case UPowerDeviceState.Discharging: return "discharging";
        case UPowerDeviceState.FullyCharged: return "full";
        case UPowerDeviceState.Empty: return "empty";
        case UPowerDeviceState.PendingCharge: return "not charging";
        case UPowerDeviceState.PendingDischarge: return "not charging";
        default: return "unknown";
        }
    }

    readonly property string text:
        `${statusText}: ` + Markup.colored(`${percent}%`, Theme.rampColor(percent))

    // Kort form: kun tallet, farvet. Ordet "discharging" fortalte ikke
    // noget Filip handlede paa -- farven og retningen goer.
    readonly property bool charging:
        device?.state === UPowerDeviceState.Charging
        || device?.state === UPowerDeviceState.FullyCharged
    readonly property string shortText: `${percent}%`

    readonly property bool visible: ready
    readonly property color color: Theme.foreground
    readonly property bool underline: false
    readonly property string tooltip: ""
}

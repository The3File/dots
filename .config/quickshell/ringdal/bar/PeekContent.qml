import QtQuick
import Quickshell
import qs
import qs.services

// Kigget. Musen blev haengende, saa pillen viser lidt mere -- men den er
// passiv. Man kan ikke komme til at goere noget ved at komme forbi.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Config.restSpacing

        Label {
            text: Wifi.connected ? Wifi.ssid : "intet net"
            color: Wifi.connected ? Theme.rampColor(Wifi.strength) : Theme.stateBad
            visible: Wifi.available
        }

        Label {
            text: Bt.anyConnected
                ? Bt.label(Bt.connectedDevices[0])
                : "ingen enhed"
            color: Bt.anyConnected ? Theme.color6 : Theme.color8
            visible: Bt.available
        }

        Label {
            text: (Audio.muted ? "lyd fra " : "lyd ") + Audio.percent + "%"
            color: Audio.muted ? Theme.color8 : Theme.rampColor(Audio.percent)
            visible: Audio.ready
        }

        Label {
            text: (Battery.charging ? "+" : "") + Battery.shortText
            color: Theme.rampColor(Battery.percent)
            visible: Battery.ready
        }

        Label {
            text: Clock.shortText
            color: Theme.foreground
        }
    }

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }
}

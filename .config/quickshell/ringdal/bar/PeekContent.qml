import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Kigget. Musen bliver haengende, og pillen folder sig ud -- men den er
// passiv. Man kan ikke komme til at goere noget ved at komme forbi.
//
// Den voksede foer sidelaens, som en bar der blev laengere. Det var forkert:
// en pille skal folde sig ud i skaermen, ikke straekke sig ud ad kanten.
// Derfor staar linjerne nu oven paa hinanden, i samme form som menuen -- saa
// kigget og det man kan klikke sig ind i ligner hinanden.
Item {
    id: root

    implicitWidth: Config.peekWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4

        Line {
            label: "wifi"
            value: Wifi.connected ? Wifi.ssid : "intet net"
            color: Wifi.connected ? Theme.rampColor(Wifi.strength) : Theme.stateBad
            visible: Wifi.available
        }

        Line {
            label: "bluetooth"
            value: Bt.anyConnected ? Bt.label(Bt.connectedDevices[0]) : "ingen enhed"
            color: Bt.anyConnected ? Theme.color6 : Theme.color8
            visible: Bt.available
        }

        Line {
            label: "lyd"
            value: Audio.muted ? "fra" : Audio.percent + "%"
            color: Audio.muted ? Theme.color8 : Theme.rampColor(Audio.percent)
            visible: Audio.ready
        }

        Line {
            label: "lys"
            value: Backlight.percent + "%"
            color: Theme.rampColor(Backlight.percent)
            visible: Backlight.percent > 0
        }

        Line {
            label: "batteri"
            value: (Battery.charging ? "+" : "") + Battery.shortText
            color: Theme.rampColor(Battery.percent)
            visible: Battery.ready
        }

        Line {
            label: "klokken"
            value: Clock.shortText
            color: Theme.foreground
        }
    }

    component Line: Item {
        property string label: ""
        property string value: ""
        property color color: Theme.foreground

        width: col.width
        height: Config.fontSize + 8

        RowLabel {
            anchors.left: parent.left
            text: parent.label
            color: Theme.color5
        }

        RowLabel {
            anchors.right: parent.right
            anchors.left: parent.horizontalCenter
            horizontalAlignment: Text.AlignRight
            text: parent.value
            color: parent.color
        }
    }
}

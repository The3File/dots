import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

// Hvad kroppen viser naar der ikke sker noget. Fire ting, og de tre af dem er
// der ikke altid.
//
// Reglen bag udvalget: et modul fortjener sin faste plads kun hvis det aendrer
// sig ofte nok til at vaere vaerd at kigge paa, OG Filip ville goere noget
// anderledes naar han saa det aendre sig. Ydelse, volumen og lysstyrke faldt
// paa det andet led -- han hoerte eller saa det allerede selv, da han aendrede
// det. De kommer tilbage som tilstande i kroppen, ikke som tekst der staar
// fremme.
Item {
    id: root

    required property ShellScreen bodyScreen

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bodyScreen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    property bool _showWorkspace: false

    // Arbejdsrummet staar ikke fremme. Det bekraefter kort at du skiftede, og
    // gaar igen -- du har det alligevel i hovedet.
    onActiveIdChanged: {
        if (activeId < 0) return;
        root._showWorkspace = true;
        hideWorkspace.restart();
    }

    Timer {
        id: hideWorkspace
        interval: Config.workspaceLinger
        repeat: false
        onTriggered: root._showWorkspace = false
    }

    Row {
        id: row
        // IKKE centerIn: parent -- forældrens bredde kommer FRA raekken,
        // saa det ville vaere en rundkreds og begge dele blev nul.
        spacing: Config.restSpacing

        // Bredden animeres, saa resten glider paa plads i stedet for at hoppe.
        Item {
            width: root._showWorkspace ? ws.implicitWidth : 0
            height: row.height
            clip: true
            Behavior on width {
                NumberAnimation { duration: Config.morphDuration; easing.type: Easing.OutCubic }
            }

            Label {
                id: ws
                anchors.verticalCenter: parent.verticalCenter
                text: root.activeId
                color: Theme.color4
                opacity: root._showWorkspace ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Config.morphDuration }
                }
            }
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
        // Terminus er en bitmap-font; uden det her udglatter Qt den til
        // uskarphed.
        renderType: Text.NativeRendering
    }
}

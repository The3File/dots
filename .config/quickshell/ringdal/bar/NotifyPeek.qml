import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.services

// Kigget paa beskederne. Musen bliver haengende paa output-pillen, og den
// viser kort hvad der ligger -- ikke hele historikken.
//
// Samme forhold til listen som kroppens kig har til menuen: kigget er
// PASSIVT. Det viser mere og goer intet. Ingen markering under musen, ingen
// knapper, ingen "ryd alle" -- der er kun ét klikmaal, og det aabner listen.
// Uden den forskel bliver de to flader den samme flade i to stoerrelser, og
// saa er der ingen grund til at have begge.
//
// Grunden til at det findes: "3 beskeder" siger hvor mange, ikke hvad. Det
// eneste man kan goere ved det tal er at klikke og se efter.
Item {
    id: root

    // Nyeste oeverst -- man laeser en historik oppefra.
    readonly property var rows: Notifs.list.slice().reverse()
    readonly property int shown: Math.min(root.rows.length, Config.notifyPeekLines)
    readonly property int hidden: root.rows.length - root.shown

    implicitWidth: Config.notifyPeekWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 2

        Repeater {
            model: root.rows.slice(0, root.shown)

            Item {
                id: line

                required property var modelData

                readonly property bool critical:
                    line.modelData.urgency === NotificationUrgency.Critical

                width: col.width
                height: Config.fontSize + 6

                Text {
                    anchors.left: parent.left
                    anchors.right: hint.left
                    anchors.rightMargin: Config.restSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: Markup.strip(line.modelData.summary)
                    color: line.critical ? Theme.stateBad : Theme.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    renderType: Text.NativeRendering
                }

                Text {
                    id: hint
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, line.width * 0.4)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: line.modelData.appName
                    color: Theme.color8
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    renderType: Text.NativeRendering
                }
            }
        }

        // Der er flere end der er plads til. Én linje, ikke en rullebjaelke --
        // samme svar som menuen og listen giver.
        Text {
            width: parent.width
            visible: root.hidden > 0
            text: `+${root.hidden} mere`
            color: Theme.color8
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            renderType: Text.NativeRendering
            topPadding: 2
        }
    }
}

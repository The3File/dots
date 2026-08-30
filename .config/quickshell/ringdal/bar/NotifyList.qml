import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.services
import qs.widgets

// Beskederne der stadig ligger. Listen, ikke boblen.
//
// Den bor her i output-pillen og ikke i kroppens menu, af samme grund som
// boblen goer: en besked er noget maskinen giver ham. Klikker han paa
// "3 beskeder", skal listen folde sig ud PAA STEDET -- ikke aabne en menu
// ovre i kroppen, hvor det han selv var i gang med, staar.
//
// Formen er menuens: en raekke pr. linje, markering under musen, venstreklik
// goer det aabenlyse, hoejreklik lukker den. Det er den samme maade at pege
// paa noget i hele pillen, saa der ikke skal laeres en ny.
Item {
    id: root

    // Nyeste oeverst. Listen er en historik, man laeser oppefra.
    readonly property var rows: Notifs.list.slice().reverse()
    readonly property int shown: Math.min(root.rows.length, Config.notifyLines)
    readonly property int hidden: root.rows.length - root.shown

    implicitWidth: Config.notifyWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4

        // Overskriften er ogsaa vejen ud. Den skal vaere her: naar listen staar
        // aaben, er "N beskeder" gemt bag den, saa der er ikke noget at klikke
        // paa igen.
        Item {
            width: parent.width
            height: Config.fontSize + 12

            RowMarker { hovered: lukHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "‹ beskeder"
                color: Theme.color5
            }

            MouseArea {
                id: lukHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Notifs.closeList()
            }
        }

        Repeater {
            model: root.rows.slice(0, root.shown)

            Item {
                id: line

                required property var modelData

                readonly property bool critical:
                    line.modelData.urgency === NotificationUrgency.Critical

                width: col.width
                height: Config.fontSize + 12

                RowMarker { hovered: lineHover.containsMouse }

                RowLabel {
                    anchors.left: parent.left
                    anchors.right: hint.left
                    anchors.rightMargin: Config.restSpacing
                    text: Markup.strip(line.modelData.summary)
                    color: line.critical ? Theme.stateBad : Theme.foreground
                }

                RowLabel {
                    id: hint
                    anchors.right: parent.right
                    width: Math.min(implicitWidth, line.width * 0.4)
                    horizontalAlignment: Text.AlignRight
                    text: line.modelData.appName
                    color: Theme.color8
                }

                MouseArea {
                    id: lineHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    // Musen paa listen holder den aabne besked i live paa samme
                    // maade som paa boblen -- man skal kunne naa at laese. Og
                    // paa samme maade bundet til om musen ER der, saa en
                    // linje der forsvinder under markoeren ikke efterlader
                    // `held` staaende som sand.
                    onContainsMouseChanged: Notifs.held = lineHover.containsMouse
                    Component.onDestruction: Notifs.held = false
                    onClicked: event => {
                        if (event.button === Qt.RightButton) {
                            Notifs.dismiss(line.modelData);
                            return;
                        }
                        Notifs.act(line.modelData);
                    }
                }
            }
        }

        // Der er flere end der er plads til. Én linje, ikke en rullebjaelke --
        // samme svar som menuen giver.
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

        Item {
            width: parent.width
            height: Config.fontSize + 12

            RowMarker { hovered: rydHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "ryd alle"
                color: Theme.color8
            }

            MouseArea {
                id: rydHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Notifs.clear()
            }
        }
    }
}

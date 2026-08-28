import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Aabnerens indhold. En linje at skrive i, og det den finder.
//
// Skrivefeltet er selve fladen -- ikke et felt inde i en dialog. Derfor ingen
// ramme om det, kun en pil foran. Formen udenom er pillen; den skal ikke have
// en kasse indeni.
Item {
    id: root

    implicitWidth: Config.launchWidth
    implicitHeight: col.implicitHeight

    // Tastaturet skal derind, saa snart fladen er der. Bindingen alene er
    // ikke nok: elementet er skjult i det oejeblik tilstanden skifter.
    onVisibleChanged: if (visible) Qt.callLater(input.forceActiveFocus)

    Column {
        id: col
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: Config.fontSize + 10

            Text {
                id: prompt
                anchors.verticalCenter: parent.verticalCenter
                text: "› "
                color: Theme.color5
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
            }

            TextInput {
                id: input

                anchors.left: prompt.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                focus: true
                color: Theme.foreground
                selectionColor: Theme.color4
                selectedTextColor: Theme.barBackground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
                cursorVisible: true

                onTextChanged: {
                    Launcher.query = text;
                    Launcher.index = 0;
                }

                // Tilstanden bor i servicen, men feltet ejer det man taster.
                // De to holdes i sync uden at binde dem til hinanden -- ellers
                // slaar de hinanden ihjel.
                Connections {
                    target: Launcher
                    function onQueryChanged(): void {
                        if (input.text !== Launcher.query) input.text = Launcher.query;
                    }
                }

                Keys.onUpPressed: Launcher.move(-1)
                Keys.onDownPressed: Launcher.move(1)
                Keys.onTabPressed: Launcher.move(1)
                Keys.onBacktabPressed: Launcher.move(-1)
                Keys.onReturnPressed: Launcher.run()
                Keys.onEnterPressed: Launcher.run()
                Keys.onEscapePressed: Launcher.close()

                cursorDelegate: Rectangle {
                    width: 2
                    color: Theme.color4
                    visible: input.cursorVisible
                }
            }
        }

        Text {
            width: parent.width
            visible: Launcher.results.length === 0
            text: "ingenting"
            color: Theme.color8
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            renderType: Text.NativeRendering
        }

        Repeater {
            model: Launcher.results

            Item {
                id: row
                required property var modelData
                required property int index

                width: col.width
                height: Config.fontSize + 12

                RowMarker {
                    hovered: hover.containsMouse
                    selected: row.index === Launcher.index
                }

                RowLabel {
                    anchors.left: parent.left
                    anchors.right: generic.left
                    anchors.rightMargin: Config.restSpacing
                    text: row.modelData.name
                    color: row.index === Launcher.index ? Theme.color4 : Theme.foreground
                }

                RowLabel {
                    id: generic
                    anchors.right: parent.right
                    width: Math.min(implicitWidth, row.width * 0.4)
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.genericName ?? ""
                    color: Theme.color8
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: Launcher.index = row.index
                    onClicked: Launcher.launch(row.modelData)
                }
            }
        }
    }
}

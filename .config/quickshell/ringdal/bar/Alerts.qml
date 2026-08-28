import QtQuick
import Quickshell
import qs
import qs.services

// Output-pillen. Den lille form ved siden af kroppen.
//
// Kroppen er INPUT -- det Filip putter ind i maskinen. Her er alt det maskinen
// giver ham tilbage: afvigelser, beskeder, og prikken der siger at Claude
// arbejder. Den findes kun naar der er noget, og fylder ingenting naar alt er
// som det plejer.
//
// Det er samme regel koffein altid har fulgt, sat i system: tastaturlaasen,
// nettet og koffein staar ikke og fortaeller at alt er i orden. De siger til,
// naar det ikke er.
Item {
    id: root

    readonly property bool locked: Keylock.locked
    readonly property bool offline: Net.visible && !Net.connected
    readonly property bool awake: Koffein.visible
    // Beskeder der stadig ligger. De hoerer til her og ikke i hvilen: er der
    // ingen, skal der ikke staa "0 beskeder" og fylde.
    readonly property int waiting: Notifs.count
    // Claude har brug for ham. Staar her og ikke i kroppen, saa den ikke kan
    // skjules af en aaben menu eller af at han dikterer.
    readonly property bool asking: Agent.waiting

    // Der bliver talt. Hoerer til her og ikke i kroppen: en talt linje er noget
    // maskinen giver ham, ikke noget han goer.
    readonly property bool talking: Tale.talking

    readonly property bool any: Agent.active || root.talking || locked || offline || awake || waiting > 0

    implicitWidth: any ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Row {
        id: row
        // IKKE centerIn: parent -- forældrens bredde kommer FRA raekken,
        // saa det ville vaere en rundkreds og begge dele blev nul.
        spacing: Config.restSpacing

        Label {
            text: "låst"
            color: Theme.stateBad
            visible: root.locked
        }

        Label {
            text: "intet net"
            color: Theme.stateBad
            visible: root.offline
        }

        // Prikken. Ingen ord -- ordene gaar gennem beskedfladen, og en linje
        // der staar stille kan alligevel ikke skelnes fra en der er gaaet i
        // staa. Det er aandedraettet der er beviset.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Agent.active ? 7 : 0
            height: 7
            visible: width > 0

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Agent.color

                SequentialAnimation on opacity {
                    running: Agent.working && !Agent.stale
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                }
            }
        }

        // Taleindikatoren. Boelgen og ordet er ÉT klikmaal -- kort tryk springer
        // den linje over, der laeses nu; hold nede goer helt tavs.
        //
        // Hvorfor den bevaeger sig: en linje der staar stille kan ikke skelnes
        // fra en der er gaaet i staa. Det er samme grund som prikken har, men
        // bevaegelsen er med vilje en anden -- prikken aander, det her svinger
        // som lyd. Ellers smelter de to sammen til én ting.
        Item {
            id: taler
            anchors.verticalCenter: parent.verticalCenter
            visible: root.talking
            width: visible ? talerRow.implicitWidth : 0
            height: talerRow.implicitHeight

            Row {
                id: talerRow
                spacing: 7

                // Boelgen. Fire streger paa fast grund -- de vokser opad, ikke
                // ud fra midten, saa formen ikke skubber til det ved siden af.
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13
                    height: 12

                    Repeater {
                        model: [0, 180, 90, 270]

                        Rectangle {
                            id: stribe

                            required property int modelData
                            required property int index

                            x: index * 4
                            width: 2
                            radius: 1
                            color: Theme.color6
                            anchors.bottom: parent.bottom

                            // Gotcha: INGEN `height:`-binding her. En binding og
                            // en animation paa samme egenskab udelukker hinanden,
                            // og bindingen vinder tavst -- stregerne stod bare
                            // stille, uden en linje i loggen. Prikken har samme
                            // grund til ikke at binde `opacity`. Derfor staar
                            // starthoejden som `from` i animationen i stedet.
                            SequentialAnimation on height {
                                running: root.talking
                                loops: Animation.Infinite
                                // Faseforskudt, saa de ikke marcherer i takt.
                                // Fire streger i lockstep ligner en indlaesning,
                                // ikke lyd.
                                PauseAnimation { duration: stribe.modelData }
                                NumberAnimation { from: 3; to: 12; duration: 260; easing.type: Easing.OutSine }
                                NumberAnimation { to: 3; duration: 300; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 8; duration: 200; easing.type: Easing.OutSine }
                                NumberAnimation { to: 3; duration: 240; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                Label { text: Tale.label; color: Theme.color6 }
            }

            MouseArea {
                anchors.fill: parent

                // Gotcha: QML sender ogsaa `clicked` efter et langt tryk, saa
                // uden det her flag ville hold-nede baade toemme koeen OG
                // springe over bagefter.
                property bool held: false

                onPressed: held = false
                onPressAndHold: { held = true; Tale.silence(); }
                onClicked: if (!held) Tale.skip()
            }
        }

        Label {
            text: "venter"
            color: Theme.stateWarn
            visible: root.asking
        }

        Label {
            text: "koffein"
            color: Theme.stateWarn
            visible: root.awake
        }

        Label {
            text: root.waiting === 1 ? "1 besked" : `${root.waiting} beskeder`
            color: Theme.color5
            visible: root.waiting > 0

            MouseArea {
                anchors.fill: parent
                onClicked: Pill.notifs()
            }
        }
    }

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }
}

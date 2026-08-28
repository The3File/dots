pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

// Lyd og lys. De staar ikke laengere fremme i pillen, fordi de kun aendrer sig
// naar Filip selv aendrer dem -- og saa hoerte eller saa han det allerede.
// Til gengaeld skal han kunne se hvor langt op han skruede, saa pillen viser
// niveauet et oejeblik og lukker sig igen.
//
// Bevaegelsen holdes lille med vilje: formskiftets stoerrelse skal svare til
// begivenhedens betydning. Lydstyrke er en lille ting og maa ikke rykke
// skaermen som en diktering goer.
Singleton {
    id: root

    readonly property bool active: _active
    // "lyd" eller "lys"
    readonly property string kind: _kind
    readonly property int value: _value
    readonly property bool muted: _kind === "lyd" && Audio.muted

    readonly property color color:
        muted ? Theme.color8 : Theme.rampColor(_value)

    property bool _active: false
    property string _kind: ""
    property int _value: 0

    // Opstart er ikke en aendring. Uden det her blinker pillen hver gang
    // shellen genindlaeses, mens Pipewire og lysstyrken finder deres vaerdier.
    //
    // Foerste forsoeg talte "foerste aendring" pr. kilde, men det var forkert:
    // lydstyrken skifter fra nul til rigtig vaerdi FOER Pipewire melder klar,
    // saa den aendring blev sprunget over uden at taelle -- og saa aad den
    // foerste rigtige tastetryk i stedet. En kort naadeperiode rammer begge
    // kilder ens og kan ikke komme ud af trit.
    property bool _settled: false

    Timer {
        running: true
        interval: Config.levelSettle
        repeat: false
        onTriggered: root._settled = true
    }

    function _show(kind: string, value: int): void {
        root._kind = kind;
        root._value = value;
        root._active = true;
        linger.restart();
    }

    Timer {
        id: linger
        interval: Config.levelLinger
        repeat: false
        onTriggered: root._active = false
    }

    Connections {
        target: Audio
        function onPercentChanged(): void {
            if (!root._settled || !Audio.ready) return;
            root._show("lyd", Audio.percent);
        }
        function onMutedChanged(): void {
            if (!root._settled || !Audio.ready) return;
            root._show("lyd", Audio.percent);
        }
    }

    Connections {
        target: Backlight
        function onPercentChanged(): void {
            if (!root._settled || Backlight.percent <= 0) return;
            root._show("lys", Backlight.percent);
        }
    }

    // Saa Claude og tastebindene kan kalde visningen frem uden at aendre noget.
    IpcHandler {
        target: "level"
        function volume(): void { root._show("lyd", Audio.percent); }
        function brightness(): void { root._show("lys", Backlight.percent); }
    }
}

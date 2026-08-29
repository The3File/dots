import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// Fladen kroppen tegnes paa. Selv er den tom og gennemsigtig.
//
// Den er hoejere end baren ser ud, fordi kroppen skal kunne vokse uden at faa
// et nyt vindue. Til gengaeld reserveres kun barens egen hoejde, saa vinduerne
// under ikke rykker sig naar den morfer.
//
// mask gør at museklik kun rammer selve kroppen -- alt det gennemsigtige
// ovenover falder igennem til vinduet bagved.
PanelWindow {
    id: root

    required property ShellScreen barScreen

    screen: barScreen
    color: "transparent"

    anchors { left: true; right: true; bottom: true }
    // Hoejt nok til den stoerste form pillen kan tage. Vinduet er
    // gennemsigtigt og klik falder igennem alt undtagen selve pillen, saa
    // hoejden koster ingenting -- og er den for lav, bliver en aaben menu
    // klippet af vindueskanten uden at noget ser forkert ud i koden.
    implicitHeight: Math.min(barScreen.height, Config.overlayHeight)

    // Pillen svæver. Den reserverer ikke plads, saa vinduerne gaar helt ud
    // til kanten -- en lille ting i et hjoerne skal ikke koste en stribe
    // hen over hele bunden. Til gengaeld kan den ligge oven paa noget i
    // selve hjoernet; det er byttet.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top

    // Bundet til geometrien og ikke bare til elementet, saa klikfladen
    // foelger med naar kroppen morfer. Radius er med, saa klik i de runde
    // hjoerner ogsaa falder igennem.
    mask: Region {
        x: body.shape.x
        y: body.shape.y
        width: body.shape.width
        height: body.shape.height
        radius: body.shape.radius

        // Afvigelses-pillen er sin egen form og skal kunne klikkes for sig.
        Region {
            x: body.alertShape.x
            y: body.alertShape.y
            width: body.alertShape.width
            height: body.alertShape.height
            radius: body.alertShape.radius
        }
    }

    // Tastaturet gribes kun naar der er en grund. Pillen maa aldrig staa og
    // stjaele det Filip skriver.
    //
    // Aabneren er den ene undtagelse der skal have det uden at man klikker:
    // man trykker Super+D og skriver videre uden at flytte musen. Det er ogsaa
    // den eneste tilstand der kan spaerre tastaturet, hvis den saetter sig
    // fast -- derfor lukker baade Esc, klik udenfor, dikteringen og
    // `qs -c ringdal ipc call launcher close` den.
    //
    // Menuen har ogsaa et felt man skriver i nu (samme soegning som fuzzel
    // havde), saa den skal ogsaa have tastaturet -- ikke kun aabneren.
    //
    // **OnDemand og ikke Exclusive** (maalt 29-08, kostede en runde at finde).
    // Med Exclusive holder Hyprland tastaturet paa laget uanset hvad, og saa
    // rydder den ALDRIG fokusgrebet -- klik uden for pillen kunne ikke lukke
    // en aaben menu, selv om grebet stod og var aktivt. Med OnDemand faar
    // laget alligevel tastaturet, fordi HyprlandFocusGrab i Body.qml selv
    // tager det saa laenge grebet holder. Skift den ikke tilbage uden at
    // proeve et klik udenfor bagefter.
    WlrLayershell.keyboardFocus: (Launcher.active || body.opened)
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Body {
        id: body
        anchors.fill: parent
        bodyScreen: root.barScreen
        hostWindow: root

        focus: true
        Keys.onEscapePressed: body.esc()
    }
}

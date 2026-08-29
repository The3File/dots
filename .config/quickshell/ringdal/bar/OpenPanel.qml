import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Den aabne tilstand: én liste man navigerer i. Fladen ved ikke hvad den
// viser -- den spoerger Menu, og Menu faar sit indhold fra Pages.
//
// **Tastaturet er vim'sk (29-08).** h j k l flytter og gaar ind og ud; der er
// ikke noget felt at skrive i. Foer laa der en soegelinje der altid havde
// tastaturet, og saa var den eneste vej gennem menuen at STAVE til det man
// ville -- man skulle kende navnet paa forhaand for at kunne pege paa det.
// En liste med ti linjer er noget man peger paa, ikke noget man beskriver.
//
// Feltet findes stadig, men kun naar der SKAL skrives: en adgangskode, eller
// en soegning han selv aabner med "/" i en lang liste. Det er den samme regel
// som resten af pillen: en flade skal fortjene sin plads.
//
// Aabneren (Super+D) er uaendret -- dér ER det at skrive hele pointen.
Item {
    id: root

    implicitWidth: Config.openWidth
    implicitHeight: col.implicitHeight

    readonly property var view: Menu.view
    readonly property int lines: Math.min(root.view.length, Config.menuLines)
    // Rullevinduet. Listen kan vaere lang; pillen maa ikke blive det.
    property int first: 0

    // Bliver der spurgt om noget (wifi-noegle, kode), skal der skrives.
    readonly property bool asking: Menu.prompt !== null
    // "/" -- han bad selv om at soege. Gaar vaek igen naar soegningen slipper.
    property bool searching: false
    readonly property bool typing: root.asking || root.searching

    focus: true

    // Tastaturet skal derhen hvor det hoerer til: ned i feltet naar der er et,
    // ellers op i listen. Bindingen alene er ikke nok -- elementet er skjult i
    // det oejeblik tilstanden skifter.
    onVisibleChanged: {
        if (visible) Qt.callLater(root._focus);
        else root.searching = false;
    }
    onTypingChanged: Qt.callLater(root._focus)

    function _focus(): void {
        if (!root.visible) return;
        if (root.typing) input.forceActiveFocus();
        else root.forceActiveFocus();
    }

    // Slut soegningen. Escape kaster ordet vaek, retur beholder det -- saa kan
    // han skrive tre bogstaver, trykke retur og pege med j og k bagefter.
    function _drop(keep: bool): void {
        if (!keep) Menu.query = "";
        root.searching = false;
    }

    // Hold det valgte inde i vinduet.
    function _follow(): void {
        if (Menu.index < root.first) root.first = Menu.index;
        else if (Menu.index >= root.first + Config.menuLines)
            root.first = Menu.index - Config.menuLines + 1;
        const max = Math.max(0, root.view.length - Config.menuLines);
        if (root.first > max) root.first = max;
    }

    Connections {
        target: Menu
        function onIndexChanged(): void { root._follow(); }
        function onViewChanged(): void { root.first = 0; root._follow(); }
        // Ny side = ny liste. En soegning fra den forrige side maa ikke
        // haenge ved og filtrere noget han lige er kommet ind i.
        function onTitleChanged(): void { root.searching = false; }
    }

    // ---- vim ---------------------------------------------------------------
    // h ud, l ind, j ned, k op. Piletasterne goer det samme, saa man ikke skal
    // vaelge side. g og G springer til enderne af en lang liste.
    Keys.onPressed: event => {
        if (root.typing) return;
        switch (event.key) {
        case Qt.Key_J:
        case Qt.Key_Down:
        case Qt.Key_Tab:
            Menu.move(1); break;
        case Qt.Key_K:
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            Menu.move(-1); break;
        case Qt.Key_L:
        case Qt.Key_Right:
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            Menu.activate(null); break;
        case Qt.Key_H:
        case Qt.Key_Left:
        case Qt.Key_Backspace:
            Menu.back(); break;
        case Qt.Key_G:
            // G i bunden, g i toppen -- som i vim.
            Menu.index = (event.modifiers & Qt.ShiftModifier)
                ? Math.max(0, root.view.length - 1) : 0;
            break;
        case Qt.Key_Slash:
            root.searching = true; break;
        // Escape lukker det, han aabnede -- ikke ét lag ad gangen.
        // Se Menu.entry.
        case Qt.Key_Escape:
            Menu.esc(); break;
        default:
            return;
        }
        event.accepted = true;
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        // ---- overskrift = vejen tilbage ----------------------------------
        Item {
            width: parent.width
            height: Config.fontSize + 12
            visible: Menu.nested || root.asking

            RowMarker { hovered: backHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "‹ " + (root.asking ? Menu.prompt.title : Menu.title)
                color: Theme.color5
            }

            MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Menu.back()
            }
        }

        // ---- linjen man skriver i ----------------------------------------
        // Findes kun naar der ER noget at skrive. Samme felt uanset om han
        // soeger i listen eller svarer paa noget; det er kun tegnene der
        // skjules, og hvad retur betyder.
        Item {
            width: parent.width
            height: Config.fontSize + 10
            visible: root.typing

            Text {
                id: prompt
                anchors.verticalCenter: parent.verticalCenter
                text: root.asking ? "kode " : "/ "
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

                color: Theme.foreground
                echoMode: root.asking ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
                cursorVisible: true

                onTextChanged: if (!root.asking) {
                    Menu.query = text;
                    Menu.index = 0;
                }

                // Feltet toemmes naar det aabner sig paa ny, saa et gammelt
                // soegeord ikke staar og filtrerer.
                Connections {
                    target: root
                    function onTypingChanged(): void {
                        if (root.typing) input.text = "";
                    }
                }
                Connections {
                    target: Menu
                    function onPromptChanged(): void { input.text = ""; }
                    function onQueryChanged(): void {
                        if (!root.asking && input.text !== Menu.query)
                            input.text = Menu.query;
                    }
                }

                // Man kan pege videre mens man soeger, uden at forlade feltet.
                Keys.onUpPressed: Menu.move(-1)
                Keys.onDownPressed: Menu.move(1)
                Keys.onTabPressed: Menu.move(1)
                Keys.onBacktabPressed: Menu.move(-1)
                Keys.onEscapePressed: {
                    // Escape slipper foerst soegningen, ikke menuen. Ellers
                    // ville et fortrudt soegeord koste hele fladen.
                    if (root.searching) root._drop(false); else Menu.esc();
                }
                Keys.onReturnPressed: root._enter()
                Keys.onEnterPressed: root._enter()

                cursorDelegate: Rectangle {
                    width: 2
                    color: Theme.color4
                    visible: input.cursorVisible
                }
            }
        }

        // ---- besked naar der ikke er en liste ----------------------------
        Text {
            width: parent.width
            visible: text !== ""
            // Status vises ogsaa mens der spoerges om noget: root-adgang
            // skriver kommandoen der, og den skal blive staaende mens koden
            // tastes.
            text: Menu.status !== "" ? Menu.status
                : (root.asking ? ""
                   : (root.view.length === 0 ? "ingenting" : ""))
            wrapMode: Text.Wrap
            color: Theme.color8
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            renderType: Text.NativeRendering
            leftPadding: 14
        }

        // ---- listen ------------------------------------------------------
        Repeater {
            model: root.asking ? []
                : root.view.slice(root.first, root.first + Config.menuLines)

            Item {
                id: line
                required property var modelData
                required property int index

                readonly property int slot: root.first + line.index
                readonly property bool picked: line.slot === Menu.index

                width: col.width
                height: Config.fontSize + 12

                RowMarker { hovered: lineHover.containsMouse; selected: line.picked }

                RowLabel {
                    id: mark
                    anchors.left: parent.left
                    width: (Menu.live(line.modelData.mark) ?? "") === "" ? 0 : Config.fontSize
                    text: Menu.live(line.modelData.mark) ?? ""
                    color: Menu.live(line.modelData.color) ?? Theme.foreground
                }

                RowLabel {
                    anchors.left: mark.right
                    anchors.leftMargin: mark.width > 0 ? 8 : 0
                    anchors.right: hint.left
                    anchors.rightMargin: Config.restSpacing
                    text: line.modelData.label ?? ""
                    color: Menu.live(line.modelData.color)
                        ?? (line.picked ? Theme.color4 : Theme.foreground)
                }

                RowLabel {
                    id: hint
                    anchors.right: parent.right
                    width: Math.min(implicitWidth, line.width * 0.45)
                    horizontalAlignment: Text.AlignRight
                    // Enhver af dem maa vaere en funktion -- se Menu.live().
                    text: Menu.live(line.modelData.hint) ?? ""
                    color: Menu.live(line.modelData.hintColor) ?? Theme.color8
                }

                MouseArea {
                    id: lineHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: Menu.index = line.slot
                    onClicked: event => {
                        if (event.button === Qt.RightButton) {
                            if (line.modelData.alt) line.modelData.alt();
                            return;
                        }
                        Menu.activate(line.modelData);
                    }
                }
            }
        }

        // Der er mere end der er plads til. Én linje, ikke en rullebjaelke.
        Text {
            width: parent.width
            visible: root.view.length > Config.menuLines
            text: `+${Math.max(0, root.view.length - Config.menuLines)} mere`
            color: Theme.color8
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            renderType: Text.NativeRendering
            leftPadding: 14
            topPadding: 2
        }
    }

    function _enter(): void {
        if (root.asking) { Menu.answer(input.text); return; }
        // Retur i en soegning vaelger ikke -- den slipper feltet med ordet i
        // behold, saa han kan pege videre med j og k.
        root._drop(true);
    }
}

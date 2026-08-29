import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Den aabne tilstand: én liste, ét filter, piletaster. Fladen ved ikke hvad
// den viser -- den spoerger Menu, og Menu faar sit indhold fra Pages.
//
// Det er med vilje den samme form som fuzzel havde: skriv for at soege, pil op
// og ned, retur for at vaelge. Det eneste der er skiftet er, at det foregaar i
// pillen i stedet for i et fremmed vindue -- og at escape lukker det han
// aabnede, i stedet for at pille ét lag af (se Menu.entry).
Item {
    id: root

    implicitWidth: Config.openWidth
    implicitHeight: col.implicitHeight

    readonly property var view: Menu.view
    readonly property int lines: Math.min(root.view.length, Config.menuLines)
    // Rullevinduet. Listen kan vaere lang; pillen maa ikke blive det.
    property int first: 0

    onVisibleChanged: if (visible) Qt.callLater(input.forceActiveFocus)

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
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        // ---- overskrift = vejen tilbage ----------------------------------
        Item {
            width: parent.width
            height: Config.fontSize + 12
            visible: Menu.nested || Menu.prompt !== null

            RowMarker { hovered: backHover.containsMouse }

            RowLabel {
                anchors.left: parent.left
                anchors.right: parent.right
                text: "‹ " + (Menu.prompt !== null ? Menu.prompt.title : Menu.title)
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
        // Samme felt uanset om man soeger i en liste eller svarer paa noget.
        // Det er kun tegnene der skjules, og hvad retur betyder.
        Item {
            width: parent.width
            height: Config.fontSize + 10

            Text {
                id: prompt
                anchors.verticalCenter: parent.verticalCenter
                text: Menu.prompt !== null ? "kode " : "› "
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
                echoMode: Menu.prompt !== null ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
                cursorVisible: true

                onTextChanged: if (Menu.prompt === null) {
                    Menu.query = text;
                    Menu.index = 0;
                }

                // Feltet toemmes naar man skifter side eller bliver spurgt om
                // noget -- ellers staar det gamle soegeord og filtrerer en
                // liste man lige er kommet ind i.
                Connections {
                    target: Menu
                    function onTitleChanged(): void { input.text = ""; }
                    function onPromptChanged(): void { input.text = ""; }
                    function onQueryChanged(): void {
                        if (Menu.prompt === null && input.text !== Menu.query)
                            input.text = Menu.query;
                    }
                }

                Keys.onUpPressed: Menu.move(-1)
                Keys.onDownPressed: Menu.move(1)
                Keys.onTabPressed: Menu.move(1)
                Keys.onBacktabPressed: Menu.move(-1)
                Keys.onLeftPressed: event => {
                    if (input.text === "") Menu.back(); else event.accepted = false;
                }
                // Escape lukker det, han aabnede -- ikke ét lag ad gangen.
                // Venstrepil og overskriften er vejen tilbage. Se Menu.entry.
                Keys.onEscapePressed: Menu.esc()
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
                : (Menu.prompt !== null ? ""
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
            model: Menu.prompt !== null ? []
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
        if (Menu.prompt !== null) { Menu.answer(input.text); return; }
        Menu.activate(null);
    }
}

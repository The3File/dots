import QtQuick
import qs

// Et modul i baren. Ved intet om hvor teksten kommer fra -- kun hvordan den
// saettes op. Padding, understregning og klik svarer 1:1 til style.css.
Item {
    id: root

    property string text: ""
    property color color: Theme.foreground
    property bool underline: false
    property color underlineColor: root.color
    property int leftPadding: Theme.itemPadding
    property int rightPadding: Theme.itemPadding

    signal clicked()
    signal rightClicked()

    readonly property alias hovered: mouse.containsMouse
    readonly property alias contentItem: label

    // Tom tekst = skjult modul, praecis som waybar gjorde det.
    visible: text !== ""
    implicitWidth: visible ? label.implicitWidth + leftPadding + rightPadding : 0
    implicitHeight: parent ? parent.height : 0

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        // Samme som workspaces: border-bottom skubbede teksten 1 px op.
        anchors.verticalCenterOffset:
            root.underline ? -Theme.underlineWidth / 2 : 0
        x: root.leftPadding
        text: root.text
        // Modulerne sender StyledText, ligesom de sendte pango til waybar.
        textFormat: Text.StyledText
        color: root.color
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        // Terminus er en bitmap-font; uden NativeRendering udglatter Qt den
        // til uskarphed.
        renderType: Text.NativeRendering
    }

    Rectangle {
        visible: root.underline
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.underlineWidth
        color: root.underlineColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) root.rightClicked();
            else root.clicked();
        }
    }
}

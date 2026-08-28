import QtQuick
import Quickshell
import qs
import qs.services

// Niveauet: ordet, tallet og en tynd bane der fyldes. Samme luft som i hvile,
// saa pillen kun bliver bredere -- ikke hoejere.
Item {
    id: root

    implicitWidth: Config.levelWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: Level.muted ? `${Level.kind} fra` : Level.kind
        color: Theme.foreground
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }

    Text {
        id: value
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: `${Level.value}%`
        color: Level.color
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }

    // Banen ligger under teksten, ikke ved siden af -- den skal kunne aflaeses
    // i et glimt uden at stjaele bredde fra tallet.
    Rectangle {
        anchors {
            left: label.right
            right: value.left
            leftMargin: Config.restSpacing
            rightMargin: Config.restSpacing
            verticalCenter: parent.verticalCenter
        }
        height: 3
        radius: height / 2
        color: Theme.color8

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * Math.max(0, Math.min(1, Level.value / 100))
            radius: parent.radius
            color: Level.color
            Behavior on width {
                NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
            }
        }
    }
}

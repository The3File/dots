import QtQuick
import Quickshell
import qs
import qs.services

// Agenten i hvile-pillens plads: en prik der aander, og den seneste linje.
//
// Prikken er der fordi en linje der staar stille ikke kan skelnes fra en linje
// der er gaaet i staa. Aandedraettet er beviset paa at der stadig sker noget.
Item {
    id: root

    implicitWidth: dot.width + gap.width + Math.min(text.implicitWidth, Config.agentWidth)
    implicitHeight: Math.max(dot.height, text.implicitHeight)

    Rectangle {
        id: dot
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 7
        radius: width / 2
        color: Agent.color

        SequentialAnimation on opacity {
            running: Agent.working
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: gap
        anchors.left: dot.right
        width: Config.restSpacing / 2
        height: 1
    }

    Text {
        id: text
        anchors.left: gap.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Config.agentWidth)
        text: Agent.line
        color: Theme.foreground
        elide: Text.ElideRight
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        renderType: Text.NativeRendering
    }
}

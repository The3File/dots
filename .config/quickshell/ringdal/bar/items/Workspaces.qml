import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Workspaces kommer fra Hyprlands egen IPC -- ingen polling, ingen scripts.
// waybar viste 1-10 permanent (persistent-workspaces), og det gaelder stadig:
// nummeret staar der, ogsaa naar der ikke er noget vindue paa det.
Row {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    // #workspaces { padding: 0 4px; }
    leftPadding: 4
    rightPadding: 4

    Repeater {
        model: 10

        Item {
            id: ws
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: root.activeId === wsId

            readonly property int padding: active
                ? Theme.workspaceActivePadding
                : Theme.workspacePadding
            readonly property int content:
                Math.max(label.implicitWidth, Theme.workspaceMinContent)

            width: content + 2 * padding
            height: root.height

            Rectangle {
                anchors.fill: parent
                color: mouse.containsMouse && !ws.active ? Theme.color0 : "transparent"
            }

            Text {
                id: label
                anchors.centerIn: parent
                // Understregningen var border-bottom i CSS'en, og en border
                // aad 2 px af knappens indhold -- derfor sad teksten 1 px
                // hoejere paa den aktive.
                anchors.verticalCenterOffset:
                    ws.active ? -Theme.underlineWidth / 2 : 0
                text: ws.wsId
                color: ws.active
                    ? Theme.color4
                    : (mouse.containsMouse ? Theme.foreground : Theme.color8)
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                renderType: Text.NativeRendering
            }

            Rectangle {
                visible: ws.active
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Theme.underlineWidth
                color: Theme.color4
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch(`workspace ${ws.wsId}`)
            }
        }
    }
}

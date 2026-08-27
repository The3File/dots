import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets
import qs.bar.items

// Selve baren. Raekkefoelgen er waybars modules-left / modules-right, ordret.
PanelWindow {
    id: root

    required property ShellScreen barScreen

    screen: barScreen
    anchors { left: true; right: true; bottom: true }
    implicitHeight: Config.barHeight
    color: Theme.barBackground

    Row {
        id: left
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }

        Workspaces { screen: root.barScreen; height: root.height }
        Sep {}
        ServiceItem { service: Perf; onClicked: Perf.openMenu() }
        Sep {}
        ServiceItem {
            service: Whspr
            onClicked: Whspr.toggleRecord()
            onRightClicked: Whspr.toggleOverlay()
        }
        Sep {}
        ServiceItem { service: Keylock; onClicked: Keylock.toggle() }
        ServiceItem { service: Koffein; onClicked: Koffein.turnOff() }
    }

    Row {
        id: right
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }

        ServiceItem { service: Audio; onClicked: Audio.toggleMute() }
        ServiceItem { service: Backlight }
        Sep {}
        ServiceItem { service: Net; onClicked: Net.openPicker() }
        Sep {}
        ServiceItem { service: Battery }
        Sep {}
        ServiceItem {
            service: Clock
            onClicked: Clock.openCalendar()
            rightPadding: Theme.clockRightPadding
        }
    }
}

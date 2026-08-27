import Quickshell
import qs
import qs.bar

// Roden. En bar pr. skaerm -- ogsaa dem der bliver sat til midt i en session.
// Config.barScreens kan snaevre det ind til fx ["eDP-1"].
ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData
            barScreen: modelData
            visible: Config.wantsScreen(modelData)
        }
    }
}

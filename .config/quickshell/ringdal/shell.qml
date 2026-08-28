import Quickshell
import qs
import qs.bar

// Roden. Én krop pr. skaerm. Alt hvad shellen viser -- bar, stemme, og senere
// menuer og notifikationer -- er tilstande i den krop, ikke selvstaendige
// vinduer.
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

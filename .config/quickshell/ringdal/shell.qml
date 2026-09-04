import Quickshell
import Quickshell.Hyprland
import qs
import qs.bar
import qs.services

// Roden. Én krop pr. skaerm. Alt hvad shellen viser -- bar, stemme, og senere
// menuer og notifikationer -- er tilstande i den krop, ikke selvstaendige
// vinduer.
ShellRoot {
    id: root

    Variants {
        id: bars

        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData
            barScreen: modelData
            visible: Config.wantsScreen(modelData)
        }
    }

    // ---- fokusgrebet ------------------------------------------------------
    // Hyprland fortaeller naar der klikkes udenfor. Uden det ville en aaben
    // menu ikke kunne lukkes med musen -- masken goer at klik udenfor pillen
    // slet ikke naar frem til os, og at klikke sig ud er den foerste ting man
    // proever.
    //
    // Grebet tager ogsaa tastaturet, saa laget behoever ikke bede om det med
    // Exclusive -- og maa ikke: Exclusive laaser tastaturet fast paa laget, og
    // saa rydder Hyprland aldrig grebet. Se kommentaren i Bar.qml.
    //
    // Der laa foer en ventetid (grabDelay) foran, fordi Hyprland meldte grebet
    // ryddet med det samme, naar vinduet endnu ikke havde faaet tastaturet.
    // Den er vaek sammen med Exclusive: nu er det grebet selv der giver
    // tastaturet, saa der er ikke noget at vente paa -- og ventetiden var
    // dyr, for i de millisekunder gik hans foerste tastetryk til vinduet
    // bagved i stedet for ned i aabneren.
    //
    // Beskedlisten er med i grebet (29-08). Den bor i output-pillen og har
    // ingen tastaturfokus, men den staar aaben fordi han selv foldede den ud
    // -- og saa skal den kunne lukkes paa den samme maade som menuen: ved at
    // klikke et andet sted. Uden grebet naar det klik aldrig frem, fordi
    // masken lader alt uden for pillerne falde igennem.
    //
    // Boblen er IKKE med: den er noget maskinen rejser, ikke noget han
    // aabnede, og den gaar over af sig selv. Det samme gaelder
    // root-spoergsmaalet ovre i kroppen -- det skal besvares, ikke klikkes
    // vaek ved et uheld, saa kroppen tager heller ikke grebet for dets skyld.
    // Kigget paa Claude er med af samme grund som beskedlisten: han foldede
    // den selv ud, og saa skal et klik ved siden af kunne lukke den igen.
    //
    // **ÉT greb, ikke ét pr. skaerm** (flyttet hertil 4/9-2026). Det laa foer
    // inde i `Body`, altsaa én gang pr. skaerm. Med to skaerme greb de begge
    // paa én gang, og Hyprland tillader kun ét: det ene skubbede det andet ud,
    // og det udskubbede svarede paa `onCleared` med at lukke pillen. De slog
    // hinanden ihjel i samme oejeblik han trykkede -- pillen aabnede sig ikke
    // paa NOGEN af skaermene, og intet saa forkert ud i koden. Det kostede en
    // aften at finde, fordi symptomet lignede en doed museknap.
    //
    // Grebet hoerer til TILSTANDEN, ikke til fladen. `Pill.opened` og de andre
    // er singletons -- der er kun én ting at gribe om, saa der skal ogsaa kun
    // vaere ét greb. `windows` er ALLE bar-vinduerne, saa et klik paa pillen
    // ovre paa den anden skaerm er "indenfor" og lukker ingenting; kun et klik
    // uden for dem alle rydder. Det er ogsaa den rigtige regel med én skaerm:
    // kroppen og afvigelses-pillen er to vinduer i samme flade, ikke to ting.
    readonly property bool wantGrab:
        Pill.opened || Launcher.active || Notifs.listing || Agent.showing

    HyprlandFocusGrab {
        active: root.wantGrab
        windows: bars.instances
        onCleared: {
            Pill.close();
            Launcher.close();
            Notifs.closeList();
            Agent.hide();
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

// Kald et script og faa linjerne tilbage. Ét kald ad gangen -- menuen er
// drevet af et menneske der klikker, ikke af noget der skal parallelisere.
//
// Ligger som komponent og ikke som singleton, saa wifi og bluetooth har hver
// sin og ikke kan afbryde hinanden midt i et scan.
Item {
    id: root

    // Stien til scriptet. Argumenterne kommer med i kaldet.
    required property string script

    readonly property bool busy: proc.running

    property var _cb: null

    function run(args, cb): void {
        if (proc.running) return;
        root._cb = cb ?? null;
        proc.command = [root.script].concat(args ?? []);
        proc.running = true;
    }

    // Linjer uden de tomme. Alle vores scripts skriver linjeorienteret.
    function lines(text: string): var {
        return String(text ?? "").split("\n").filter(l => l.trim() !== "");
    }

    Process {
        id: proc

        stdout: StdioCollector {
            id: out
            // Vi laeser her og ikke i onExited: teksten er foerst hel naar
            // stroemmen er lukket, og de to ting kommer ikke i fast orden.
            onStreamFinished: {
                const cb = root._cb;
                root._cb = null;
                if (cb) cb(out.text ?? "");
            }
        }
    }
}

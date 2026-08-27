pragma Singleton

import Quickshell

// Baren tegner sin tekst som StyledText, praecis som waybar tegnede pango.
// Her ligger de to ting alle moduler har brug for: sikker escaping, og
// oversaettelsen af de pango-spans scriptene stadig sender.
Singleton {
    id: root

    function esc(s: string): string {
        return String(s ?? "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
    }

    // Farvet stump tekst.
    function colored(text: string, color): string {
        return `<font color="${color}">${esc(text)}</font>`;
    }

    // runbar-color.sh sender pango: <span foreground="#5b0">45%</span>.
    // Vi vil ikke lade markup fra et script slippe uset ind i vores tekst, saa
    // strengen bygges op stump for stump: alt uden for en span escapes, og
    // selve spannen oversaettes til StyledText.
    function fromPango(s: string): string {
        const src = String(s ?? "");
        const re = /<span foreground="([^"]*)">([\s\S]*?)<\/span>/g;
        let out = "";
        let last = 0;
        let m;
        while ((m = re.exec(src)) !== null) {
            out += esc(src.slice(last, m.index));
            out += `<font color="${m[1]}">${esc(m[2])}</font>`;
            last = m.index + m[0].length;
        }
        return out + esc(src.slice(last));
    }
}

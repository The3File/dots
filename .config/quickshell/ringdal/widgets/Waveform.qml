import QtQuick
import qs

// Boelgen. Ved intet om hyprwhspr -- den faar et udslag og en tilstand, og
// tegner. Derfor kan den ogsaa bruges til andet der skal lytte.
//
// Selve formen er den staaende sinus fra det gamle GTK-vindue: én amplitude
// for hele kurven, ganget med sin(pi*t) saa enderne bliver liggende paa
// midterlinjen. Det er dét der gjorde at den lignede en stemme og ikke en
// equalizer. Farverne og stregtykkelsen er nye.
Item {
    id: root

    // 0..1. Hvor meget kurven slaar ud.
    property real level: 0
    // Faar kurven til at aande i stedet for at foelge stemmen.
    property bool breathing: false
    property color colorLeft: Theme.color4
    property color colorRight: Theme.color6

    // Hoejeste udslag som andel af halv hoejde.
    property real reach: 0.48
    // Boelgelaengde i pixels, ikke antal cyklusser. Bliver kroppen bredere,
    // kommer der flere boelger -- de bliver ikke trukket ud. 150 px er dét
    // der giver præcis de to cyklusser det gamle 300 px-vindue havde.
    property real wavelength: 150
    readonly property real cycles: Math.max(1, width / wavelength)
    // Nok til at kurven er bloed; flere punkter ses ikke.
    readonly property int samples: 96

    // Mellem to aflaesninger glider udslaget i stedet for at hoppe. Motoren
    // skriver ti gange i sekundet, skaermen tegner tres -- den her fylder
    // hullet ud.
    property real _amp: level
    Behavior on _amp {
        NumberAnimation { duration: Config.voiceLevelInterval; easing.type: Easing.OutQuad }
    }
    onLevelChanged: _amp = level

    property real _phase: 0

    // Rolig drift mens der lyttes; fuld fart mens der taenkes.
    NumberAnimation on _phase {
        running: root.visible
        loops: Animation.Infinite
        from: 0
        to: 2 * Math.PI
        duration: root.breathing ? 1400 : 4000
    }

    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    on_PhaseChanged: canvas.requestPaint()
    on_AmpChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const cy = h / 2;
            ctx.reset();
            if (w <= 0 || h <= 0) return;

            // Mens der taenkes er der ingen stemme at foelge, saa kurven
            // trækker vejret i stedet for at ligge doed.
            let amp = root._amp;
            if (root.breathing)
                amp = Math.max(amp, 0.7) * (0.82 + 0.18 * Math.sin(root._phase));
            amp = Math.max(0, Math.min(1, amp));

            const reach = h * root.reach;
            const pts = [];
            for (let i = 0; i < root.samples; i++) {
                const t = i / (root.samples - 1);
                // sin(pi*t) pinder enderne fast paa midten, saa kurven ikke
                // ser klippet af.
                const s = Math.sin(t * 2 * Math.PI * root.cycles + root._phase)
                        * Math.sin(Math.PI * t);
                pts.push([t * w, cy - amp * reach * s]);
            }

            const grad = ctx.createLinearGradient(0, 0, w, 0);
            grad.addColorStop(0, root.colorLeft);
            grad.addColorStop(1, root.colorRight);

            // Blødt fyld ned til midterlinjen -- giver kurven vaegt uden at
            // tage opmaerksomhed.
            ctx.beginPath();
            ctx.moveTo(pts[0][0], cy);
            for (const p of pts) ctx.lineTo(p[0], p[1]);
            ctx.lineTo(pts[pts.length - 1][0], cy);
            ctx.closePath();
            ctx.globalAlpha = 0.14;
            ctx.fillStyle = grad;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.strokeStyle = grad;

            // Glød under stregen, saa den ikke ser tegnet ud.
            ctx.globalAlpha = 0.22;
            ctx.lineWidth = 5;
            ctx.stroke();

            ctx.globalAlpha = 0.95;
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }
    }
}

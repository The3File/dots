#!/usr/bin/env python3
"""Dikteringen skal lande i det vindue, han stod i -- ikke i det, der
tilfaeldigvis staar der, naar transskriptionen er faerdig.

Der gaar sekunder fra trykket til teksten er klar, og i dem kan han naa at
klikke et andet sted hen. Derfor to greb, sat ned i hyprwhspr udefra fra
``hyprwhspr-service`` (samme vej ind som ``WaybarStatePresenter``, saa selve
pakken kan opdateres uden at det her ryger med):

  1. Naar en optagelse STARTER, gemmer vi adressen paa det fokuserede vindue.
     Grebet sidder paa ``_start_recording`` og ikke i de to trykscripts
     (``hyprwhspr-record-toggle``, ``buds-tryk``), fordi dikteringen ogsaa kan
     startes ad veje der ikke gaar gennem dem -- hyprwhsprs egen genvej,
     ``hyprwhspr record start`` fra en terminal, styresocket'en. Ét sted er
     nok, naar stedet er der, hvor optagelsen faktisk begynder.
  2. Lige FOER teksten indsaettes, fokuserer vi vinduet igen og venter paa, at
     fokus faktisk er landet. Det retter to ting paa én gang: teksten rammer
     rigtigt, og ``text_injector`` slaar sin indsaettelsesgenvej op paa det
     rigtige vindue (terminaler skal have Ctrl+Shift+V, resten Ctrl+V).

Er vinduet vaek, kastes teksten ikke bort: den lander i udklipsholderen, og
pillen folder udklipsmenuen ud, saa han kan tage den derfra. Filips eget valg
-- en besked alene ville han skulle handle paa; menuen ER handlingen.

Pillen kan aldrig blive det gemte vindue: den er en lag-flade, og
``hyprctl activewindow`` svarer kun paa rigtige vinduer.
"""

from __future__ import annotations

import json
import os
import subprocess
import time
from pathlib import Path

# Samme mappe som visualizer_state -- ryddes af sig selv ved genstart.
_RUNTIME = Path(
    os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
) / "hyprwhspr"
TARGET_FILE = _RUNTIME / "target_window"

# Hvor laenge vi venter paa, at Hyprland har flyttet fokus, foer vi indsaetter.
FOCUS_TIMEOUT = 0.6
FOCUS_POLL = 0.03
# Cliphist fanger udklippet gennem en wl-paste-vagt; den skal naa at skrive,
# foer menuen aabnes, ellers staar linjen ikke oeverst.
CLIP_SETTLE = 0.25


def _run(argv: list[str], timeout: float = 1.0) -> tuple[int, str]:
    try:
        r = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout
    except Exception:
        return 1, ""


def _active_address() -> str:
    """Adressen paa det fokuserede vindue, eller "" hvis der ikke er noget."""
    rc, out = _run(["hyprctl", "activewindow", "-j"], timeout=0.5)
    if rc != 0:
        return ""
    try:
        win = json.loads(out)
    except Exception:
        return ""
    if not isinstance(win, dict):
        return ""
    return str(win.get("address") or "")


# --------------------------------------------------------------- gem vinduet

def gem_vindue() -> None:
    """Skriv det fokuserede vindue ned. Kaldes naar optagelsen starter."""
    try:
        # Ét tomt svar er dyrt: det sender hele dikteringen i udklip i stedet
        # for ind i vinduet. Opslaget tager 5 ms, saa spoerg hellere to gange.
        addr = _active_address()
        if not addr:
            time.sleep(0.04)
            addr = _active_address()
        _RUNTIME.mkdir(parents=True, exist_ok=True)
        TARGET_FILE.write_text(addr)
    except Exception as e:
        # Filen skal hellere mangle end vaere forkert: en manglende fil
        # betyder "vi naaede ikke at kigge", og saa indsaettes som foer.
        print(f"[FOKUS] Kunne ikke gemme vinduet: {e}", flush=True)
        try:
            TARGET_FILE.unlink(missing_ok=True)
        except Exception:
            pass


def _hent_vindue() -> str | None:
    """None = der blev aldrig kigget. "" = intet vindue var fokuseret."""
    try:
        return TARGET_FILE.read_text().strip()
    except Exception:
        return None


def _findes(address: str) -> bool:
    rc, out = _run(["hyprctl", "clients", "-j"], timeout=0.8)
    if rc != 0:
        return False
    try:
        clients = json.loads(out)
    except Exception:
        return False
    return any(
        isinstance(c, dict) and c.get("address") == address for c in clients
    )


def _fokuser(address: str) -> bool:
    """Flyt fokus tilbage og vent paa, at det er sket.

    Hyprland er sat op i Lua her, og dér fejler ``hyprctl dispatch focuswindow``
    (det bliver laest som Lua og er ikke gyldigt). ``hl.dispatch(hl.dsp.focus(…))``
    er vejen -- den henter ogsaa vinduet frem, hvis det ligger paa en anden
    arbejdsflade eller i en scratchpad.
    """
    _run(
        [
            "hyprctl",
            "eval",
            f"hl.dispatch(hl.dsp.focus({{ window = 'address:{address}' }}))",
        ],
        timeout=0.8,
    )
    frist = time.monotonic() + FOCUS_TIMEOUT
    while time.monotonic() < frist:
        if _active_address() == address:
            return True
        time.sleep(FOCUS_POLL)
    return False


# ------------------------------------------------------------ udklips-vejen

def til_udklip(text: str) -> bool:
    """Vinduet er vaek: laeg teksten i udklip og fold udklipsmenuen ud."""
    # Ingen roer paa wl-copy: den bliver staaende i baggrunden og BETJENER
    # udklipsholderen, saa en opsamlet stdout ville foerst lukke, naar den doer.
    try:
        r = subprocess.run(["wl-copy"], input=text.encode("utf-8"), timeout=2.0)
        ok = r.returncode == 0
    except Exception as e:
        print(f"[FOKUS] wl-copy fejlede: {e}", flush=True)
        ok = False
    if not ok:
        print("[FOKUS] Teksten kunne ikke lagres i udklip", flush=True)
        return False

    try:
        from desktop_notify import notify

        notify(
            "hyprwhspr",
            "Vinduet var vaek. Teksten ligger i udklip.",
            urgency="normal",
            timeout_ms=5000,
        )
    except Exception:
        pass

    time.sleep(CLIP_SETTLE)
    _run(["qs", "-c", "ringdal", "ipc", "call", "pill", "udklip"], timeout=2.0)
    print("[FOKUS] Vindue ikke fundet -- teksten lagt i udklip", flush=True)
    return True


# ------------------------------------------------------------- pille-vejen

def til_pillen(text: str) -> bool:
    """Staar pillens frie linje aaben, hoerer teksten til DER."""
    # Pillen kan aldrig vaere det gemte maalvindue -- den er en lag-flade, og
    # `hyprctl activewindow` svarer kun paa rigtige vinduer. Uden det her ville
    # en diktering, mens feltet staar aabent, altsaa lande i vinduet BAG
    # pillen, eller i udklip. Og feltet er netop bygget til at kunne bruges
    # uden at aabne et vindue.
    #
    # Der spoerges paa INDSAETNINGS-tidspunktet og ikke da optagelsen begyndte:
    # det er nu, teksten findes, og han kan naa at lukke feltet imens.
    rc, ud = _run(["qs", "-c", "ringdal", "ipc", "call", "pill", "felt"],
                  timeout=2.0)
    if rc != 0 or ud.strip() != "fri":
        # "kode" er ogsaa et nej. En adgangskode siger man ikke hoejt, og den
        # er skjult i feltet, saa han kunne ikke se om den blev rigtig.
        return False

    # `--`: uden den laeser qs en linje der starter med en bindestreg som sit
    # eget flag, og kaldet falder lydloest paa gulvet.
    rc, _ = _run(["qs", "-c", "ringdal", "ipc", "call", "pill", "udfyld",
                  "--", text], timeout=2.0)
    if rc != 0:
        print("[FOKUS] Pillen tog ikke imod teksten", flush=True)
        return False

    # Der trykkes IKKE retur for ham. Teksten ligger i feltet, saa han kan se
    # den og selv sende den -- en talt linje kan have et forkert ord i sig, og
    # det her er den ene vej ind i en koerende session.
    print("[FOKUS] Teksten lagt i pillens felt", flush=True)
    return True


# ------------------------------------------------------------------- greb

def anvend(app_class) -> None:
    """Saet begge greb ned i hyprwhsprApp."""
    if getattr(app_class, "_fokus_patched", False):
        return

    orig_start = app_class._start_recording
    orig_inject = app_class._inject_text

    def _start_recording(self, *args, **kwargs):
        # Kun ved en optagelse der faktisk begynder. Et tryk oven i en
        # koerende optagelse ville ellers overskrive med det vindue, han er
        # havnet i undervejs -- praecis den fejl, det her skal fjerne.
        if not getattr(self, "is_recording", False):
            gem_vindue()
        return orig_start(self, *args, **kwargs)

    def _inject_text(self, text):
        # Optageklienten henter teksten selv; saa er der intet vindue i spil.
        try:
            if self._recording_control_server.has_capture_subscriber():
                return orig_inject(self, text)
        except Exception:
            pass

        # Pillens felt vinder over alt andet. Det er den eneste modtager der
        # ikke er et vindue, og det er ogsaa den eneste der er valgt bevidst:
        # staar feltet der, har han lige selv aabnet det.
        if til_pillen(text):
            return

        target = _hent_vindue()
        if target is None:
            return orig_inject(self, text)  # der blev aldrig kigget

        if target and _findes(target):
            if _fokuser(target):
                return orig_inject(self, text)
            print(f"[FOKUS] Fokus landede ikke paa {target}", flush=True)

        return til_udklip(text)

    app_class._start_recording = _start_recording
    app_class._inject_text = _inject_text
    app_class._fokus_patched = True
    print("[INIT] Fokus: teksten lander i det vindue, trykket kom fra", flush=True)

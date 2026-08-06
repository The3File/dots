#!/usr/bin/env bash
# Waybar status for hyprwhspr — Terminus-friendly labels (no nerd icons).
# States: mic (idle) | rec (recording) | wait (transcribing)

set -euo pipefail

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyprwhspr"
viz_state=""
if [[ -f $runtime/visualizer_state ]]; then
	viz_state="$(tr -d '[:space:]' <"$runtime/visualizer_state" || true)"
fi

raw="$(/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh status 2>/dev/null || true)"
[[ -n $raw ]] || {
	printf '%s\n' '{"text":"mic","class":"stopped","tooltip":"hyprwhspr unavailable"}'
	exit 0
}

python3 - "$raw" "$viz_state" <<'PY'
import json, sys

raw = sys.argv[1]
viz = (sys.argv[2] or "").lower()

try:
    data = json.loads(raw)
except Exception:
    print('{"text":"mic","class":"error","tooltip":"hyprwhspr: bad status"}')
    raise SystemExit(0)

cls = data.get("class") or "ready"
tooltip = data.get("tooltip", "hyprwhspr")

# Prefer our click hints over upstream tray script text.
hint = "Left-click: toggle record\nRight-click: toggle Mic-OSD overlay"
lines = [ln for ln in tooltip.split("\n") if not ln.startswith("Left-click:") and not ln.startswith("Right-click:")]
# Insert hints after the first status line
if lines:
    tooltip = lines[0] + "\n\n" + hint + ("\n" + "\n".join(lines[1:]) if len(lines) > 1 else "")
else:
    tooltip = hint

if cls == "recording" or viz == "recording":
    label, out_cls = "rec", "recording"
elif viz == "processing":
    label, out_cls = "wait", "processing"
    tooltip = "hyprwhspr: Transcribing…\n\n" + hint
elif viz == "paused":
    label, out_cls = "pause", "paused"
elif viz == "error" or cls == "error":
    label, out_cls = "mic!", "error"
else:
    label = {
        "ready": "mic",
        "stopped": "mic",
        "unloaded": "mic",
        "error": "mic!",
    }.get(cls, "mic")
    out_cls = cls

print(json.dumps({"text": label, "class": out_cls, "tooltip": tooltip}, ensure_ascii=False))
PY

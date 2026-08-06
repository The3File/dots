#!/usr/bin/env bash
# Runbar-style threshold colors for waybar custom modules.
# Usage: runbar-color.sh {vol|light|net|bat}

set -euo pipefail

# Same ramp as ~/.Scripts/runbar get_color (incl. quirky $2/$4 reuse).
get_color() {
	local color="#0c0"
	[[ $1 -gt ${2:-85} ]] && color="#0c0"
	[[ $1 -le ${2:-85} ]] && color="#5b0"
	[[ $1 -le ${2:-70} ]] && color="#9b0"
	[[ $1 -le ${3:-55} ]] && color="#ba0"
	[[ $1 -le ${4:-40} ]] && color="#c80"
	[[ $1 -le ${4:-25} ]] && color="#d50"
	[[ $1 -le ${5:-10} ]] && color="#f00"
	printf '%s' "$color"
}

span() {
	local color="$1" text="$2"
	printf '<span foreground="%s">%s</span>' "$color" "$text"
}

json_text() {
	python3 -c 'import json,sys; print(json.dumps({"text": sys.argv[1], "tooltip": False}))' "$1"
}

vol() {
	local volume mute v color
	volume="$(pamixer --get-volume)"
	mute="$(pamixer --get-mute)"
	if [[ $mute == true ]]; then
		v="(${volume}%)"
		color="$(get_color 0)"
	else
		v="${volume}%"
		color="$(get_color "$volume")"
		[[ $volume -gt 100 ]] && color="#f00"
	fi
	json_text "vol: $(span "$color" "$v")"
}

light() {
	local bl="/sys/class/backlight/amdgpu_bl1"
	local cur max pct color
	read -r cur <"$bl/brightness"
	read -r max <"$bl/max_brightness"
	pct=$((cur * 100 / max))
	color="$(get_color "$pct")"
	json_text "scrn: $(span "$color" "${pct}%")"
}

net() {
	local iface="wlp3s0"
	local ssid signal_line signal_val signal_unit ip color out

	if ! iw "$iface" link 2>/dev/null | grep -q 'Connected\|SSID'; then
		# ethernet fallback
		if ip -br link show enp2s0f0 2>/dev/null | grep -q UP \
			&& ip -4 -br addr show enp2s0f0 2>/dev/null | grep -q -v 'DOWN'; then
			ip="$(ip -4 -br addr show enp2s0f0 | awk '{print $3}' | cut -d/ -f1)"
			[[ -n $ip ]] && { json_text "eth: [${ip}]"; return; }
		fi
		json_text "$(span "#f00" "no connection")"
		return
	fi

	read -ra ssid_arr < <(iw "$iface" link | grep SSID)
	ssid="${ssid_arr[1],,}"
	read -ra sig_arr < <(iw "$iface" link | grep 'signal')
	# e.g. signal: -45 dBm
	signal_val="${sig_arr[1]}"
	signal_unit="${sig_arr[2]}"
	# dBm: green when good, red only when really bad (not runbar's -20/-60 cutoffs)
	# > -55 green, then step down to red by about -80
	color="$(wifi_color "$signal_val")"
	read -ra ip_arr < <(ip a s "$iface" | grep 'inet ')
	ip="${ip_arr[1]%%/*}"
	out="${ssid}: $(span "$color" "${signal_val} ${signal_unit}") [${ip}]"
	json_text "$out"
}

wifi_color() {
	# Typical Wi-Fi: better than -60 green/good; -85 and worse red
	local s="$1" color="#0c0"
	[[ $s -le -60 ]] && color="#5b0"
	[[ $s -le -65 ]] && color="#9b0"
	[[ $s -le -70 ]] && color="#ba0"
	[[ $s -le -75 ]] && color="#c80"
	[[ $s -le -80 ]] && color="#d50"
	[[ $s -le -85 ]] && color="#f00"
	printf '%s' "$color"
}

bat() {
	local bat0="/sys/class/power_supply/BAT0"
	local status capacity color status_l
	read -r status <"$bat0/status"
	read -r capacity <"$bat0/capacity"
	status_l="${status,,}"
	color="$(get_color "$capacity")"
	json_text "${status_l}: $(span "$color" "${capacity}%")"
}

case "${1:-}" in
	vol) vol ;;
	light) light ;;
	net) net ;;
	bat) bat ;;
	*) echo "usage: $0 {vol|light|net|bat}" >&2; exit 1 ;;
esac

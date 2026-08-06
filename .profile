#!/bin/sh


#### GPU ####
# driver:
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
# No R600_TEX_ANISO — Mesa stderr-spams every GL app when set
#############

export XDG_CONFIG_HOME="$HOME/.config"
export USER=$(whoami)

export PATH="$HOME/.Scripts/:$HOME/.bin:$HOME/.local/bin:$HOME/.Scripts/:/usr/local/bin:$PATH"
export TERMINAL="alacritty"
export VISUAL="nvim_visual"
export EDITOR="nvim_visual"
export SYSTEMD_EDITOR="nvim"
export BROWSER="qutebrowser"

export CONFIG="$HOME/.config/bspwm/bspwmrc"
export NOTES="$HOME/Documents/Arbejde"
export SKOLE="$HOME/Documents/Arbejde/HF"
export BUDGET_FILE="$HOME/Dokumenter/budget.tab"

export PANELFIFO="/tmp/panel-fifo"
export GAPFIFO="/tmp/gap-fifo"
export BARFIFO="/tmp/bar-fifo"
export WORKFIFO="/tmp/work-fifo"

#export LOCALHOST="$(ip a | grep 'inet 192' | awk '{print $2}')"

## < TERMUX

termux_specific(){
	ANDROID=1
	read -r USER < $HOME/.username
	export $USER
	export VISUAL="nvim"
	export HOSTNAME=termux
	export SDCARD="/sdcard"
	export NOTES="/sdcard/Noter"
	export MANPAGER="less"
	alias xdg-open="termux-open"
	alias notify-send="termux-notification -c"
	[[ $TERM =~ "screen" ]] || exec tmux new -A -s termux
}

[[ $(uname -o) = "Android" ]] && termux_specific

## >

[[ -f ~/.bashrc ]] && source ~/.bashrc
# [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &>/dev/null
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
	exec start-hyprland &>/dev/null
fi

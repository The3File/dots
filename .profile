#!/bin/sh

export XDG_CONFIG_HOME="$HOME/.config"
export USER=$(whoami)

export PATH="$HOME/.Scripts/:$HOME/.bin:$HOME/.local/bin:$HOME/.Scripts/:/usr/local/bin:$PATH"
export TERMINAL="alacritty"
export VISUAL="$TERMINAL -e nvim"
export EDITOR="nvim"
export SYSTEMD_EDITOR="nvim"
export BROWSER="qutebrowser"

export CONFIG="$HOME/.config/bspwm/bspwmrc"
export NOTES="$HOME/Documents/Arbejde"
export SKOLE="$HOME/documents/Skole"
export BUDGET_FILE="$HOME/Dokumenter/budget.tab"

export PANELFIFO="/tmp/panel-fifo"
export GAPFIFO="/tmp/gap-fifo"
export BARFIFO="/tmp/bar-fifo"
export WORKFIFO="/tmp/work-fifo"

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
[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &>/dev/null

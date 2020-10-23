#!/bin/sh

export XDG_CONFIG_HOME="$HOME/.config"

export PATH=$HOME/.bin:/usr/local/bin:$HOME/.Scripts/:$PATH
export VISUAL="nvim"
export EDITOR="nvim"
export BROWSER="qutebrowser"

export CONFIG="$HOME/.config/bspwm/bspwmrc"
export NOTES="$HOME/Dokumenter/Noter"

export PANELFIFO="/tmp/panel-fifo"
export GAPFIFO="/tmp/gap-fifo"
export BARFIFO="/tmp/bar-fifo"
export WORKFIFO="/tmp/work-fifo"

if [[ $(uname -o) = "Android" ]];then
   export NOTES="/sdcard/Noter"
   alias xdg-open="termux-open"
	alias notify-send="termux-notification -c"
   [[ $TERM =~ "screen" ]] ||
      exec tmux new -A -s termux
fi

dot pull
[[ -f ~/.bashrc ]] && source ~/.bashrc
[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &>/dev/null

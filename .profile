#!/bin/sh

export XDG_CONFIG_HOME="$HOME/.config"

export PATH=$HOME/.bin:/usr/local/bin:$HOME/.Scripts/:$PATH
export VISUAL="st -e nvim"
export EDITOR="nvim"
export BROWSER="qutebrowser"

export CONFIG="$HOME/.config/bspwm/bspwmrc"
export NOTES="$HOME/Dokumenter/Noter"
export BUDGET_FILE="$HOME/Dokumenter/budget.tab"

export PANELFIFO="/tmp/panel-fifo"
export GAPFIFO="/tmp/gap-fifo"
export BARFIFO="/tmp/bar-fifo"
export WORKFIFO="/tmp/work-fifo"

if [[ $(uname -o) = "Android" ]];then
   export NOTES="/sdcard/Noter"
   export MANPAGER="less"
   alias xdg-open="termux-open"
	alias notify-send="termux-notification -c"
   [[ $TERM =~ "screen" ]] ||
      exec tmux new -A -s termux
fi

[[ -f ~/.bashrc ]] && source ~/.bashrc
[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &>/dev/null

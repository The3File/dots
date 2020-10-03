#!/bin/sh

[[ -f ~/.bashrc ]] && source ~/.bashrc

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

[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &>/dev/null

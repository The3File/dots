# ~/.bashrc

[[ -f ~/.aliases ]] 	&& source ~/.aliases
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt
[[ $(uname -o) = "Android" ]] || eval "$(thefuck --alias)"

#expressvpn status | sed 2Q
#bspc query -N -n focused.local

set -o vi
shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear:c:ll:lla:la"

[[ $(uname -o) = "Android" && $TERM != "screen" ]] &&
   exec tmux new -A -s termux

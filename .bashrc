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

<<<<<<< HEAD
open_with_fzf() { fd -t f -H -I | fzf -m --preview="xdg-mime query default {}" | xargs -ro -d "\n" xdg-open 2>&-; }
cdc() { cd $HOME && cd "$(fd -t d | fzf --preview="tree -L 1 {}" --bind="space:toggle-preview" --preview-window=:hidden)"; }
pacs() { sudo pacman -Syy $(pacman -Ssq | fzf -m --preview="pacman -Si {}" --preview-window=:hidden --bind=space:toggle-preview); }
=======
[[ $(uname -o) = "Android" && $TERM != "screen" ]] &&
   exec tmux new -A -s termux

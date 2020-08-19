# ~/.bashrc

set -o vi
source $HOME/.aliases
source $HOME/.bash_prompt

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set show-all-if-ambiguous on"
bind "set mark-symlinked-directories on"

shopt -s histappend
shopt -s cmdhist

PROMPT_COMMAND='history -a'

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"

export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

eval "$(register-python-argcomplete pmbootstrap)"

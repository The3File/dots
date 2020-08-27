# ~/.bashrc

set -o vi
source $HOME/.aliases
source $HOME/.bash_prompt

shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear:c:ll:lla:la"

eval "$(register-python-argcomplete pmbootstrap)"

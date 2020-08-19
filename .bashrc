# ~/.bashrc

set -o vi
source $HOME/.aliases
source $HOME/.bash_prompt

shopt -s histappend
shopt -s cmdhist

PROMPT_COMMAND='history -a'

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"

export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

eval "$(register-python-argcomplete pmbootstrap)"

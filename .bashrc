# ~/.bashrc

set -o vi
source $HOME/.aliases
source $HOME/.bash_prompt

shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null

PROMPT_COMMAND='history -a'

get_term_size() {
    # '\e7':           Save the current cursor position.
    # '\e[9999;9999H': Move the cursor to the bottom right corner.
    # '\e[6n':         Get the cursor position (window size).
    # '\e8':           Restore the cursor to its previous position.
    IFS='[;' read -sp $'\e7\e[9999;9999H\e[6n\e8' -d R -rs _ LINES COLUMNS
}

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"

export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

eval "$(register-python-argcomplete pmbootstrap)"

# ~/.bashrc

# set vi mode
set -o vi

#{{{ sane settings

[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

export MANPAGER="sh -c 'col -bx | bat -l man -p --paging always'"
PROMPT_DIRTRIM=2

bind Space:magic-space
bind "set show-all-if-ambiguous on"

shopt -s globstar 2> /dev/null
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s expand_aliases

#}}}
#{{{ history

shopt -s histappend

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:history -r:clear:c:ll:lla:la:reverse_fzf_history:fuzzy_cd:fuzzy_kill"

#}}}
#{{{ aliases

[[ -f ~/.aliases ]] 	&& source ~/.aliases

reverse_fzf_history(){
   local cmd="$(history | sort -nr | fzf --height 40% --reverse | cut -d ' ' -f 4-)"
   printf '%s' "${cmd}" >> "$HOME/.bash_history"
   eval -- "${cmd}"
   history -r
   unset cmd
}

fuzzy_cd() {
   local dir="$(fd -H -t d . $HOME | fzf --preview='tree -L 1 {}'\
      --bind='space:toggle-preview' --preview-window=:hidden)"
   [[ ! -z "$dir" ]] && cd "$dir"
   unset dir
}

pac() {
   sudo pacman -S $(pacman -Ssq | fzf -m --preview="pacman -Si {}"\
      --preview-window=:hidden --bind=space:toggle-preview)
}

#}}}
#{{{ termux

if [[ $(uname -o) = "Android" ]];then
   export NOTES="/sdcard/Noter"
   alias xdg-open="termux-open"
   notify-send(){ termux-notification -c "$1";}
   [[ $TERM =~ "screen" ]] ||
      exec tmux new -A -s termux
fi

#}}}
# vim: fdm=marker

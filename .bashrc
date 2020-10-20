# ~/.bashrc
#{{{ bindings

bind -u reverse-search-history
bind -u reverse-search-history
bind '"\C-r":"reverse_fzf_history"'
bind '"\C-f":"fuzzy_cd"'
bind '"\C-h":"here"'
bind '"\C-g":"gotop"'
bind '"\C-k":"fuzzy_kill"'

# set vi mode
set -o vi

#}}}
#{{{ settings

export MANPAGER="sh -c 'col -bx | bat -l man -p'"

[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s expand_aliases

#}}}
#{{{ history

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

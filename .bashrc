# ~/.bashrc

[[ -f ~/.aliases ]] 	&& source ~/.aliases
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

bind -u reverse-search-history
bind -u reverse-search-history
bind '"\C-r":"reverse_fzf_history"'
bind '"\C-f":"fuzzy_cd"'
bind '"\C-g":"gotop"'
bind '"\C-k":"fuzzy_kill"'

# set vi mode
set -o vi

# settings
shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s expand_aliases

# history
HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:history -r:clear:c:ll:lla:la:reverse_fzf_history:fuzzy_cd"

# aliases
reverse_fzf_history(){
<<<<<<< HEAD
   local cmd="$(history | fzf --height 40% --reverse | cut -d ' ' -f 4-)"
   printf '%s' "${cmd}" >> "$HOME/.bash_history"
   eval -- "${cmd}"
   history -r
=======
   local cmd="$(history | sort -nr | fzf --height 40% --reverse | cut -d ' ' -f 4-)"
   printf '%s\n' "$cmd"
   eval "$cmd"
>>>>>>> 0f1f929038702c938caab98e4ed87af9523fad76
   unset cmd
}

fuzzy_cd() {
<<<<<<< HEAD
   local dir="$(fd -H -t d . $HOME | fzf --preview='tree -L 1 {}'\
      --bind='space:toggle-preview' --preview-window=:hidden)"
   [[ ! -z "$dir" ]] && cd "$dir"
=======
   local dir=$(fd -H -t d . $HOME | fzf --preview="tree -L 1 {}"\
      --bind="space:toggle-preview" --preview-window=:hidden --height 30% --reverse)
   [[ ! -z $dir ]] && cd $dir
>>>>>>> 0f1f929038702c938caab98e4ed87af9523fad76
   unset dir
}

pac() {
   sudo pacman -S $(pacman -Ssq | fzf -m --preview="pacman -Si {}"\
      --preview-window=:hidden --bind=space:toggle-preview)
}

if [[ $(uname -o) = "Android" ]];then
   export NOTES="/sdcard/Noter"
   [[ $TERM =~ "screen" ]] ||
      exec tmux new -A -s termux
#else
#   eval "$(thefuck --alias)"
fi

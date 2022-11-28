# ~/.bashrc

# set vi mode
set -o vi

#####################
### sane settings ###
#####################

[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

export MANPAGER="sh -c 'col -bx | bat -l man --paging=always -p'"
PROMPT_DIRTRIM=2

bind Space:magic-space
bind "set show-all-if-ambiguous on"

shopt -s globstar 2> /dev/null
shopt -s cmdhist
shopt -s autocd 2>/dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s expand_aliases

###############
### history ###
###############

shopt -s histappend

HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:history -r:clear:c:ll:lla:la:reverse_fzf_history:fuzzy_cd:fuzzy_kill"
#read -r tac "$HISTFILE" | awk '!x[$0]++' > /tmp/tmpfile  && f $(< "$hist")

#################
### shortcuts ###
#################

[[ -f ~/.aliases ]] && source ~/.aliases
for dir in ~/Projekter/*;{ [[ -d $dir ]] && declare "${dir##*/}"="$dir"; }

dff(){ printf '\e[s'; for((;;)){ sed -n "1P;/$1/p" < <(df -h); read -rt 1; printf '\e[u\e[J'; }; }
ggrep(){ sed -n "1P;/sed/d;/$1/p"; }

reverse_fzf_history(){
   local cmd="$(history | sort -nr | fzf --height 40% --reverse | cut -d ' ' -f 4-)"
   printf '%s' "${cmd}" >> "$HOME/.bash_history"
   eval -- "${cmd}"
   history -r
   unset cmd
}

fuzzy_kill(){
	local pid="$(ps aux | sort | fzf | awk '{print $2}')"
	kill -9 $pid && echo "killed $pid"
	unset pid
}

fuzzy_cd() {
   local dir="$(fd -H -t d . $HOME/.config $HOME/Projekter |\
      fzf --preview='tree -L 1 {}'\
      --bind='space:toggle-preview' --preview-window=:hidden)"
   [[ ! -z "$dir" ]] && cd "$dir"
   unset dir
}

pac() {
   sudo pacman -S $(pacman -Ssq | fzf -m --preview="pacman -Si {}"\
      --preview-window=:hidden --bind=space:toggle-preview)
}


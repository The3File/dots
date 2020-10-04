# ~/.bashrc

[[ -f ~/.aliases ]] 	&& source ~/.aliases
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

#expressvpn status | sed 2Q
#bspc query -N -n focused.local

# set vi mode
set -o vi

# settings
shopt -s histappend
shopt -s cmdhist
shopt -s autocd 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s cdspell 2> /dev/null

# history
HISTSIZE=500000
HISTFILESIZE=100000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear:c:ll:lla:la"

# aliases

cdc() {
   dir=$(fd -t d . $HOME | fzf --preview="tree -L 1 {}"\
      --bind="space:toggle-preview" --preview-window=:hidden)
   [[ ! -z $dir ]] && cd $dir
}

pac() { pacman -Ssq | fzf -m --preview="pacman -Si {}" --preview-window=:hidden --bind=space:toggle-preview | xargs -r sudo pacman -S; }

if [[ $(uname -o) = "Android" ]];then
   [[ $TERM != "screen-256color" ]] &&
      exec tmux new -A -s termux
   export NOTES="/sdcard/Noter"
else
   eval "$(thefuck --alias)"
fi

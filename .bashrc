# ~/.bashrc

[[ -f ~/.aliases ]] 	&& source ~/.aliases
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

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
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear:c:ll:lla:la"

# aliases

cdc() {
   dir=$(fd -H -t d . $HOME | fzf --preview="tree -L 1 {}"\
      --bind="space:toggle-preview" --preview-window=:hidden)
   [[ ! -z $dir ]] && cd $dir
}

sv(){
   local files=($(fd -c always -d 1 -t x . $HOME/.Scripts/ $HOME/.bin/))
   file=$(printf '%s\n' "${files[@]#*${HOME##*/}/}" | fzf --ansi -0 -1 -q "$1"\
   --preview "bat --theme="OneHalfDark"\
   --style=numbers,changes --color always {}")
   [[ $file ]] && nvim "$HOME/$file"
   unset files file
}

pac() {
   pacman -Ssq | fzf -m --preview="pacman -Si {}"\
   --preview-window=:hidden --bind=space:toggle-preview |
   xargs -r sudo pacman -S
}

if [[ $(uname -o) = "Android" ]];then
   export NOTES="/sdcard/Noter"
   [[ $TERM =~ "screen" ]] ||
      exec tmux new -A -s termux
else
   eval "$(thefuck --alias)"
   #expressvpn status | sed 2Q
   #bspc query -N -n focused.local
fi

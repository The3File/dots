#!/usr/bin/env sh

config="$HOME/.dotfiles"
config(){ /usr/bin/git --git-dir="$config" --work-tree="$HOME" $@; }

git clone --bare git@github.com:The3File/dots.git "$config"

config checkout || {
   echo "Backing up existing files to \".dotfiles-backup/\"."
   mkdir -p .dotfiles-backup
   config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} "$HOME/.dotfiles-backup/"{}
}
config config status.showUntrackedFiles no

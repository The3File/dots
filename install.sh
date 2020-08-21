#!/usr/bin/env sh

config(){ /usr/bin/git --git-dir="$config" --work-tree="$HOME" "$@"; }

checkout(){
   config checkout || {
      echo "Backing up existing files to \"$backup/\"."
      [[ ! -d "$backup" ]] && mkdir -p "$backup"

      config checkout 2>&1 | while read line
      do
	 file=$(printf '%s\n' "$line" | awk {'print $1'})
	 mv "$file" "$backup$file"
      done
      config checkout
      config config status.showUntrackedFiles no
   }
}

main(){
   config="$HOME/.dotfiles/"
   backup="$HOME/.dotfiles-backup/"

   if [[ ! -e "$config/*" ]];then
      git clone --bare git@github.com:The3File/dots.git "$config"
   else
      printf '%s\n' "exiting: $config is not empty"
      exit 1
   fi

   checkout
}

main

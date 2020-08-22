config(){ /usr/bin/git --git-dir="$config" --work-tree="$HOME" "$@"; }

backup(){
   printf '%s \"%s\"\n' "Backing up existing files to" "$backup/"
   [[ ! -d "$backup" ]] && mkdir -p "$backup"

   config checkout 2>&1 | while read -r line; do
         file=$(printf '%s\n' "$line" | awk '{print $1}')
      [[ -e $file ]] && {
         mkdir -p "$backup/$file"
         mv "$file" "$backup/$file"
      }
   done
   config checkout
   config config status.showUntrackedFiles no
}

main(){
   config="$HOME/.dotfiles"
   backup="$HOME/.dotfiles-backup"
   
   printf '%s\n%s' ".dotfiles" "install.bash"
   if [[ -d "$config" || ! -e "$config/*" ]];then
      git clone --bare git@github.com:The3File/dots.git "$config"
      config checkout || backup
   else
      printf '%s\n' "exiting: $config is not empty"
      exit 1
   fi

}

main

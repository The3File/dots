config="$HOME/.dotfiles"
backup="$HOME/.dotfiles-backup"

[[ "$(ls -A "$config")" ]] && { printf '%s\n' "exiting: $config is not empty"; exit 1; }

config(){ git --git-dir="$config" --work-tree="$HOME" "$@"; }
backup(){ printf '%s \"%s\"\n' "Conflicting files, attempting backup to" "$backup/"
   [[ ! -d "$backup" ]] && mkdir -p "$backup"

   config checkout 2>&1 | while read -r line; do
      file=$(printf '%s\n' "$line" | awk '{print $1}')
      [[ -e $file ]] && { mkdir -p "$backup/$file"
         mv "$file" "$backup/$file"; }
   done; config checkout; config config --local status.showUntrackedFiles no; }

printf '%s\n%s\n%s' ".dotfiles" "install.bash" "README.md" > "$HOME/.gitignore"

read -rp "[ssh/url]: "
case $REPLY in
   s|ssh)
      git clone --bare git@github.com:The3File/dots.git "$config"
      ;;
   u|url)
      git clone --bare https://github.com/The3File/dots.git "$config"
esac

config checkout &>/dev/null || backup

#!/bin/sh

xset +fp /usr/share/fonts/TTF
xset +fp /usr/share/fonts/OTF

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# X settings
exec xsetroot -cursor_name left_ptr &
exec xset -dpms &
exec xset s off &
exec setxkbmap -layout dk -variant nodeadkeys -option caps:escape &

# Daemons
exec picom --experimental-backends --config .config/compton.conf &
exec xbanish -i Mod1 -i Mod4 &
exec networkd-dispatcher &
exec /usr/lib/kdeconnectd &
exec dunst &
exec acpid_events &
exec greenclip daemon &
exec sxhkd &

# Wallpaper & colorscheme
exec wal -Rtn &
exec feh --bg-fill $HOME/.config/wall.png &

bspwm

#!/bin/sh

xset +fp /usr/share/fonts/TTF
xset +fp /usr/share/fonts/OTF

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# X settings
exec xsetroot -solid "#333333" -cursor_name left_ptr &
exec xset -dpms &
exec xset s off &
#exec setxkbmap -layout dk -variant nodeadkeys -option caps:swapescape -option "shift:both_capslock" &

# User apps
exec networkd-dispatcher &
exec swallow &
exec unclutter -idle 3 &
exec clipmenud &
exec feh --bg-fill $HOME/.config/wall.png &
exec picom -b &

# WM
exec sxhkd -m 1 &
exec bspwm
#lockscreen nolock &
#dwm

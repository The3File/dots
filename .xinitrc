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
exec setxkbmap -layout dk -variant nodeadkeys -option caps:swapescape -option "shift:both_capslock" &

# User apps
exec networkd-dispatcher &
exec swallow &
exec clipmenud &
exec feh --bg-fill $HOME/.config/wall.png &

# WM
exec sxhkd -m 1 &
lockscreen nolock &
bspwm

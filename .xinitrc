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
#exec picom --experimental-backends &
exec xbanish -i Mod1 -i Mod4 &
exec networkd-dispatcher &
exec /usr/lib/kdeconnectd &
exec dunst &
exec swallow &
exec acpid_events &
exec greenclip daemon &
exec expressvpn connect dk &
exec wal -Rtn &
exec feh --bg-fill $HOME/.config/wall.png &

# WM
exec sxhkd &
bspwm

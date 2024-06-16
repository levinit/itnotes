#!/bin/bash
session=xfce #${1:-gnome}

case $session in
gnome) 
    export XDG_SESSION_TYPE=x11
    export GDK_BACKEND=x11
    session=gnome-session 
    ;;
xfce | xfce4)
    which xrdb &>/dev/null && xrdb -merge ~/.Xresources
    session=startxfce4
    ;;
kde* | plasma*)
    export DESKTOP_SESSION=plasma
    session=startplasma-x11
    ;;
esac

echo "$session" > ~/.xsession
exec dbus-launch "$session"

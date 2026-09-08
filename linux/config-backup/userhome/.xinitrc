#!/bin/bash
session=cosmic #${1:-gnome}

case $session in
cosmic)
    session=start-cosmic
    #which xrdb &>/dev/null && xrdb -merge ~/.Xresources
    ;;
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

if [[ -z $(command -v $session) ]];
then
  echo "$session not found" >> start-session.err
  exit 1
fi


echo "$session" >~/.xsession

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

exec dbus-run-session -- "$session"
# exec dbus-launch "$session"

#for vnc
#vncserver -kill $DISPLAY

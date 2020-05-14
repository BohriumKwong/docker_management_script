#!/bin/bash

# setting vnc password
if [ $VNC_PASSWORD ];
then
echo
else
VNC_PASSWORD=123456
fi

echo vnc password is $VNC_PASSWORD
echo $VNC_PASSWORD > /root/.vncpasswd

if [ $RESOLUTION ];
then
echo
else
RESOLUTION=1280x720x24
fi

echo $RESOLUTION > /root/.RESOLUTION

# start X virtual buffer, autostart by supervisord
# /usr/bin/Xvfb :1 -screen 0 $(cat /root/.RESOLUTION) -nolisten tcp &

# start desktop, autostart by supervisord
# export DISPLAY=:1 && openbox &
# export DISPLAY=:1 && lightdm-session &
## export DISPLAY=:1 && /usr/bin/startlxqt &

# start x11vnc, autostart by supervisord
# /usr/bin/x11vnc -listen 0.0.0.0 -rfbport 5900 -xkb -shared -repeat -noxdamage -passwd $(cat /root/.vncpasswd) -display :1 -forever -loop &

# run noVNC, autostart by supervisord
# /noVNC-1.1.0/utils/launch.sh --vnc 127.0.0.1:5900

# 自动启动fcitx
fcitx-autostart;

# . /root/anaconda3/bin/deactivate
/usr/bin/supervisord -n

# ssh -NfR 5901:127.0.0.1:5901 smb@192.168.3.163

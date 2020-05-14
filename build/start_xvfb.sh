#!/bin/sh
killall -9 Xvfb ; rm /tmp/.X1-lock ; cat /root/.RESOLUTION | xargs -i Xvfb :1 -screen 0 {} -nolisten tcp

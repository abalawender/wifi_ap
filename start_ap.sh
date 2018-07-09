#!/bin/bash

WIFI_IF=wlan0

echo starting docker...
docker run -e WIFI_IF=${WIFI_IF} -e TZ=$(cat /etc/timezone) \
    --cap-add=SYS_PTRACE --cap-add=NET_ADMIN --rm -dit --name "olafur" access_point

echo moving phy...
WIFI_PHY=$(</sys/class/net/${WIFI_IF}/phy80211/name)
sudo iw phy ${WIFI_PHY} set netns $(docker inspect -f '{{.State.Pid}}' olafur)

echo attaching...
docker attach olafur

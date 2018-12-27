#!/bin/bash
#sudo dpkg-reconfigure -f noninteractive tzdata

## if WIFI_IF was not specified, we'll take the first one to appear
shopt -s nullglob
while [[ -z "${WIFI_IF}" ]]; do
    sleep 1;
    WIFI_IF=$(echo /sys/class/net/*/wireless | cut -d/ -f 5);
done

cat <<EOF > /etc/network/interfaces
iface ${WIFI_IF} inet static
    address 192.168.111.1/24
    post-up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    post-up iptables -A FORWARD -i eth0 -o ${WIFI_IF} -m state --state RELATED,ESTABLISHED -j ACCEPT
    post-up iptables -A FORWARD -i ${WIFI_IF} -o eth0 -j ACCEPT
    hostapd /etc/hostapd.conf
EOF

cat <<EOF > /etc/hostapd.conf
# the interface used by the AP
interface=${WIFI_IF}
# the socket used to communicate with frontend programs
ctrl_interface=/var/run/hostapd
# g simply means 2.4GHz
hw_mode=g
# the channel to use
channel=10
# limit the frequencies used to those allowed in the country
ieee80211d=1
# the country code
country_code=PL
# 802.11n support
ieee80211n=1
# QoS support
wmm_enabled=1

# First AP
ssid=test0
# if there is no encryption defined, none will be used
#wpa=1
#wpa_passphrase=testpwd1
EOF

cat <<EOF > /etc/dnsmasq.conf
port=0
# Only listen to routers' LAN NIC.  Doing so opens up tcp/udp port 53 to
# localhost and udp port 67 to world:
interface=${WIFI_IF}

# dnsmasq will open tcp/udp port 53 and udp port 67 to world to help with
# dynamic interfaces (assigning dynamic ips). Dnsmasq will discard world
# requests to them, but the paranoid might like to close them and let the 
# kernel handle them:
bind-interfaces

# Optionally set a domain name
domain=nesttest.com

# Set default gateway
dhcp-option=3,192.168.111.1

# Set DNS servers to announce
dhcp-option=6,8.8.8.8,8.8.4.4

# Dynamic range of IPs to make available to LAN PC and the lease time.
# Ideally set the lease time to 5m only at first to test everything works okay before you set long-lasting records.
dhcp-range=192.168.111.50,192.168.111.200,12h
EOF

while [[ ! $(ip addr show dev ${WIFI_IF}) ]]; do sleep 1; done

ifup ${WIFI_IF} || exit 1
dnsmasq #--log-dhcp

#split-window "hostapd /etc/hostapd.conf ; read" \; \
#split-window "dnsmasq -d --log-dhcp" \; \
tmux \
  new-session "tcpdump -i ${WIFI_IF}" \; \
  split-window "hostapd_cli" \; \
  split-window "ps fx; bash" \; \
  select-layout tiled

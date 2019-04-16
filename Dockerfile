FROM ubuntu:14.04.5
RUN apt-get update

##required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install hostapd dnsmasq iptables
##extras
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install iw tcpdump tmux

##configuration
#ENV WIFI_IF=wlan0
#COPY hostapd.conf /etc/hostapd.conf
#COPY dnsmasq.conf /etc/dnsmasq.conf
#COPY interfaces /etc/network/interfaces
COPY container_init.sh /

HEALTHCHECK --interval=15s --retries=1 --start-period=1m CMD iw dev | grep -q 'type AP'

CMD /container_init.sh

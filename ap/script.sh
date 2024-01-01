#!/bin/bash
killall hostapd 2> /dev/null
killall dnsmasq 2> /dev/null
bssid=""
ssid=""
channel=""
int="wlan1"
while getopts "b:s:c:" opt; do
	case $opt in
	b)
		bssid=$OPTARG
		;;
	s)
		ssid=$OPTARG
		;;
	c)
		channel=$OPTARG
		;;
	*)
		echo "Invalid option: -$opt"
		exit 1
		;;
	esac
done
if [ -z "$bssid" ]; then
	echo "Please specify a BSSID with -b XXX to create the AP"
	exit 1
fi

if [ -z "$ssid" ]; then
	echo "Please specify an SSID with -s XXX to create the AP"
	exit 1
fi

if [ -z "$channel" ]; then
	echo "Please specify a channel with -c XX to create the AP"
	exit 1
fi

# HOSTAPD template
HOSTAPD_TEMPLATE=$(
	cat <<EOF
interface=$int
driver=nl80211
ssid=$ssid
hw_mode=g
channel=$channel
macaddr_acl=0
auth_algs=1
wmm_enabled=1
EOF
)
echo "$HOSTAPD_TEMPLATE" > /tmp/hostapd.conf
# DNSMASQ template
DNSMASQ_TEMPLATE=$(
cat <<EOF
interface=$int
# IP range that can be given to clients
dhcp-range=10.0.0.10,10.0.0.100,255.255.255.0,8h
# Gateway ip address
dhcp-option=3,10.0.0.1
# Set dns server address
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
listen-address=127.0.0.1
#Redirect all requests to 10.0.0.1
address=/#/10.0.0.1
EOF
)
echo "$DNSMASQ_TEMPLATE" > /tmp/dnsmasq.conf
# ----------------------------------------------------
# Kill all processes related to networking
airmon-ng check kill &> /dev/null 
# ----------------------------------------------------
# Shutdown interface
ip link set down $int 2> /dev/null
# Change macaddress 
macchanger -r $int
# Set ip 
ip address add 10.0.0.1/24 dev $int
ip link set up $int 
# Change macaddress 
# ----------------------------------------------------
#        Enable kernel package forwarding 			 
# ----------------------------------------------------
echo 1 > /proc/sys/net/ipv4/ip_forward
# ----------------------------------------------------
#    		      IPTABLES			 
# ----------------------------------------------------
# Flush rules
iptables -F
iptables --table nat -F
# Masquerade
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
# Forwarding
iptables --append FORWARD --in-interface $int -j ACCEPT
# ----------------------------------------------------
#    			TMUX SESSION			 
# ----------------------------------------------------
# Kill wifi session 
# tmux kill-session -t wifi 2> /dev/null 
# Naming  sessions
# tmux new -s wifi -n "hostapd" -d 
#tmux new-window -t wifi -n "dnsmasq"
# Send keys  C-m means new line
#tmux send-keys -t wifi:dnsmasq "dnsmasq -C /tmp/dnsmasq.conf -d" C-m
#tmux send-keys -t wifi:hostapd 'hostapd /tmp/hostapd.conf | tee /tmp/hostapd.log' C-m
#tmux attach
dnsmasq -C /tmp/dnsmasq.conf -d &
hostapd /tmp/hostapd.conf | tee /tmp/hostapd.log





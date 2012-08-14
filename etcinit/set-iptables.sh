#!/bin/bash
IPT="/sbin/iptables"

#### IPS ######
# Get server public ip 
SERVER_IP=$(ifconfig eth0 | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
 
#### FILES #####
BLOCKED_IP_TDB=/root/.fw/blocked.ip.txt
SPOOFIP="127.0.0.0/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 169.254.0.0/16 0.0.0.0/8 240.0.0.0/4 255.255.255.255/32 168.254.0.0/16 224.0.0.0/4 240.0.0.0/5 248.0.0.0/5 192.0.2.0/24"
BADIPS=$( [[ -f ${BLOCKED_IP_TDB} ]] && egrep -v "^#|^$" ${BLOCKED_IP_TDB})
 
### Interfaces ###
PUB_IF="eth0"   # public interface
LO_IF="lo"      # loopback
 
#### Clear out old tables ####
$IPT -F
$IPT -X

### start firewall ###
echo "Setting LB1 $(hostname) Firewall..."
 
# Unlimited lo access
$IPT -A INPUT -i ${LO_IF} -j ACCEPT
$IPT -A OUTPUT -o ${LO_IF} -j ACCEPT

# Allow related stuff.
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Drop sync
$IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP
 
# Drop Fragments
# $IPT -A INPUT -i ${PUB_IF} -f -j DROP
 
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP
 
# Drop NULL packets
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix " NULL Packets "
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP
 
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
 
# Drop XMAS
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix " XMAS Packets "
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
 
# Drop FIN packet scans
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix " Fin Packets Scan "
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP
 
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Drop Dropbox packets
$IPT -A INPUT -i ${PUB_IF} -p udp --dport 17500 -j DROP
 
# Log and get rid of broadcast / multicast and invalid 
#$IPT  -A INPUT -i ${PUB_IF} -m pkttype --pkt-type broadcast -j LOG --log-prefix " Broadcast "
#$IPT  -A INPUT -i ${PUB_IF} -m pkttype --pkt-type broadcast -j DROP
 
$IPT  -A INPUT -i ${PUB_IF} -m pkttype --pkt-type multicast -j LOG --log-prefix " Multicast "
$IPT  -A INPUT -i ${PUB_IF} -m pkttype --pkt-type multicast -j DROP
 
$IPT  -A INPUT -i ${PUB_IF} -m state --state INVALID -j LOG --log-prefix " Invalid "
$IPT  -A INPUT -i ${PUB_IF} -m state --state INVALID -j DROP
 
# Log and block spoofed ips
#$IPT -N spooflist
#for ipblock in $SPOOFIP
#do
#         $IPT -A spooflist -i ${PUB_IF} -s $ipblock -j LOG --log-prefix " SPOOF List Block "
#         $IPT -A spooflist -i ${PUB_IF} -s $ipblock -j DROP
#done

#$IPT -I INPUT -j spooflist
#$IPT -I OUTPUT -j spooflist
#$IPT -I FORWARD -j spooflist
 
# Allow ssh
$IPT -A INPUT -i ${PUB_IF} -p tcp -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -p tcp -j ACCEPT
 
# allow incoming ICMP ping pong stuff
$IPT -A INPUT -i ${PUB_IF} -p icmp --icmp-type 8 -s 0/0 -m state --state NEW,ESTABLISHED,RELATED -m limit --limit 30/sec  -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -p icmp --icmp-type 0 -d 0/0 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# allow HTTP port 80 
$IPT -A INPUT -i ${PUB_IF} -p tcp -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -p tcp -j ACCEPT

# allow HTTPS port 443
$IPT -A INPUT -i ${PUB_IF} -p tcp -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -p tcp -j ACCEPT

# allow incoming DHCP requests
$IPT -A INPUT -i ${PUB_IF} -p udp --dport 67:68 --sport 67:68 -j ACCEPT
 
# allow outgoing ntp 
$IPT -A OUTPUT -o ${PUB_IF} -p udp --dport 123 -j ACCEPT
 
# allow outgoing smtp
$IPT -A OUTPUT -o ${PUB_IF} -p tcp --dport 25 -j ACCEPT

# allow outgoing DNS
$IPT -A OUTPUT -o ${PUB_IF} -p udp -s $SERVER_IP --sport 1024:65535 --dport 53 -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -p tcp --dport 53 -j ACCEPT

# allow outgoing FTP
$IPT -A OUTPUT -o ${PUB_IF} -p tcp --dport 21 -j ACCEPT

# Allow outgoing Active FTP Connections
$IPT -A OUTPUT -o ${PUB_IF} -p tcp --dport 20 -m state --state ESTABLISHED -j ACCEPT 

# Allow outgoing Passive FTP Connections
$IPT -A OUTPUT -o ${PUB_IF} -p tcp --sport 1024: --dport 1024:  -m state --state ESTABLISHED,RELATED -j ACCEPT 

#######################
# drop and log everything else
$IPT -A INPUT -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix " DEFAULT DROP "
$IPT -A INPUT -j DROP
 
# DROP and close everything 
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP
 
exit 0

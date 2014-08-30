#!/bin/bash

cat > /etc/iptables.conf <<'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m limit --limit 5/min --limit-burst 7 -j LOG --log-prefix " NULL Packets "
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -m limit --limit 5/min --limit-burst 7 -j LOG --log-prefix " XMAS Packets "
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/min --limit-burst 7 -j LOG --log-prefix " Fin Packets Scan "
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
-A INPUT -i eth0 -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,ACK,URG -j DROP
-A INPUT -i eth0 -p udp -m udp --dport 17500 -j DROP
-A INPUT -i eth0 -m pkttype --pkt-type multicast -j LOG --log-prefix " Multicast "
-A INPUT -i eth0 -m pkttype --pkt-type multicast -j DROP
-A INPUT -i eth0 -m state --state INVALID -j LOG --log-prefix " Invalid "
-A INPUT -i eth0 -m state --state INVALID -j DROP
-A INPUT -i eth0 -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 25 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 21 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 111 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 37426 -j ACCEPT
-A INPUT -i eth0 -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -m limit --limit 30/sec -j ACCEPT
-A INPUT -i eth0 -p udp -m udp --sport 67:68 --dport 67:68 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 9200 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 25 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 465 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 995 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 143 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 993 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 110 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 587 -j ACCEPT
-A INPUT -m limit --limit 5/min --limit-burst 7 -j LOG --log-prefix " DEFAULT DROP "

-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 22 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 80 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 443 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 25 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 21 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 111 -j ACCEPT
-A OUTPUT -o eth0 -p udp -m udp --dport 123 -j ACCEPT
-A OUTPUT -s 10.0.2.15/32 -o eth0 -p udp -m udp --sport 1024:65535 --dport 53 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 53 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --dport 20 -m state --state ESTABLISHED -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m tcp --sport 1024:65535 --dport 1024:65535 -m state --state RELATED,ESTABLISHED -j ACCEPT
COMMIT
EOF

chmod 600 /etc/iptables.conf

cat > /etc/network/if-pre-up.d/iptables <<'EOF'
#!/bin/sh

# Load iptables rules before interfaces are brought online
# This ensures that we are always protected by the firewall
#
# Note: if bad rules are inadvertently (or purposely) saved it could block
# access to the server except via the serial tty interface.
#

RESTORE=/sbin/iptables-restore
STAT=/usr/bin/stat
IPSTATE=/etc/iptables.conf

test -x $RESTORE || exit 0
test -x $STAT || exit 0

# Check permissions and ownership (rw------- for root)
if test `$STAT --format="%a" $IPSTATE` -ne "600"; then
  echo "Permissions for $IPSTATE must be 600 (rw-------)"
  exit 0
fi

# Since only the owner can read/write to the file, we can trust that it is
# secure. We need not worry about group permissions since they should be
# zeroed per our previous check; but we must make sure root owns it.
if test `$STAT --format="%u" $IPSTATE` -ne "0"; then
  echo "The superuser must have ownership for $IPSTATE (uid 0)"
  exit 0
fi

# Now we are ready to restore the tables
$RESTORE < $IPSTATE


echo "Done with $(hostname) Firewall..."
EOF

chmod 755 /etc/network/if-pre-up.d/iptables

echo "Finished setting up iptables. You must restart for it to take effect!"


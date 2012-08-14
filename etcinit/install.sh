#!/usr/bin/zsh

sudo set-iptables.sh
sudo iptables-save > /etc/iptables.conf
sudo chmod 600 /etc/iptables.conf
sudo cp iptables /etc/network/if-pre-up.d/

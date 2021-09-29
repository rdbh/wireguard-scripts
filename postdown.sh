#!/bin/bash
set -ex

# Traffic forwarding
iptables -D FORWARD -i %i -j ACCEPT
iptables -D FORWARD -o %i -j ACCEPT

# Nat
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# DNS
iptables -D INPUT -s 10.100.0.1/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -D INPUT -s 10.100.0.1/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
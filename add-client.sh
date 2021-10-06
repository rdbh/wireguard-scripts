#!/bin/bash
# Add Wireguard Client to Ubuntu Server
# (C) 2021 Richard Dawson 

if [ $# -eq 0 ]
then
	echo "must pass a client name as an arg: add-client.sh <new-client>"
else
	echo "Creating client config for: $1"
	mkdir -p clients/$1
	wg genkey | (umask 0077 && tee clients/$1/$1.priv) | wg pubkey > clients/$1/$1.pub
	priv_key=$(cat clients/$1/$1.priv)
	pub_key=$(cat clients/$1/$1.pub)
	
	#command line ip address or generated
	if [ $2 -eq 0 ]
	then
		reldir=`dirname $0`
		ip="10.100.200."$(expr $(cat /etc/wireguard/last-ip.txt | tr "." " " | awk '{print $4}') + 1)
		echo $ip > /etc/wireguard/last-ip.txt
	else
		ip=$2
	fi
	
	FQDN=$(hostname -f)
	HOSTIP=$(ip -o route get to 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
	
	#Try to get server IP address
	if [[ ${HOSTIP} == "" ]]
	then
	    echo "Server IP not found automatically. Update wg0.conf before sending to clients"
		HOSTIP="<Insert IP HERE>"
	fi
	
    server_pub_key=$(cat /etc/wireguard/server_public_key)
	ip3=`echo $ip | cut -d"." -f1-3`.0
	
	# Create the client config
    cat /etc/wireguard/wg0-client.example.conf | sed -e 's/:CLIENT_IP:/'"$ip"'/' | sed -e 's|:CLIENT_KEY:|'"$priv_key"'|' | sed -e 's/:ALLOWED_IPS:/'"$ip3"'/' | sed -e 's|:SERVER_PUB_KEY:|'"$server_pub_key"'|' | sed -e 's|:SERVER_ADDRESS:|'"$HOSTIP"'|' > clients/$1/wg0.conf
	
	# Add client (peer) to server config
	peer="\n[Peer]\n" + "PublicKey = " + ${pub_key} + "\nAllowedIPs = " + ${ip}
	printf $peer >> /etc/wireguard/wg0.conf
	sudo systemctl restart wg-quick@wg0.service
	
	echo ${ip} > /etc/wireguard/last-ip.txt
	cp install-client.sh clients/$1/install-client.sh
	zip -r clients/$1.zip clients/$1
	tar czvf clients/$1.tar.gz clients/$1
	echo "Created config!"
	echo "Adding peer"
	sudo wg set wg0 peer $(cat clients/$1/$1.pub) allowed-ips $ip/32
	echo "Adding peer to hosts file"
	echo $ip" "$1 | sudo tee -a /etc/hosts
	sudo wg show
	qrencode -t ansiutf8 < clients/$1/wg0.conf
	qrencode -o clients/$1/$1.png < clients/$1/wg0.conf
fi

#!/bin/bash
# Add Wireguard Client to Ubuntu Server
# (C) 2021 Richard Dawson 

## Global Variables
FQDN=$(hostname -f)
HOSTIP=$(ip -o route get to 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
peer_name=""

if [ $# -eq 0 ]
then
	echo "must pass a client name as an arg: add-client.sh <new-client>"
	exit 1
else if [ $1 == "-c" ]
then
	peer_name=$2
	echo "Creating client config for: $peer_name"
	mkdir -p clients/$2
	wg genkey | (umask 0077 && tee clients/$peer_name/$peer_name.priv) | wg pubkey > clients/$peer_name/$peer_name.pub
	
	# get command line ip address or generated from last-ip.txt
	if [ $3 -eq 0 ]
	then
		reldir=`dirname $0`
		ip="10.100.200."$(expr $(cat /etc/wireguard/last-ip.txt | tr "." " " | awk '{print $4}') + 1)
		sudo echo $ip > /etc/wireguard/last-ip.txt
		sudo echo ${ip} > /etc/wireguard/last-ip.txt
	else
		ip=$3
	
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
	cp install-client.sh clients/$peer_name/install-client.sh
	zip -r clients/$peer_name.zip clients/$peer_name
	tar czvf clients/$peer_name.tar.gz clients/$peer_name
	echo "Created config files"

else
	peer_name=$1
	# get command line ip address or generated from last-ip.txt
	if [ $2 -eq 0 ]
	then
		# get ip address from wg0.conf
		ip=$(sed -n -e '/Address=/ s/.*\= *//p' /clients/$1/wg0.conf)
	else
		ip=$2
fi
echo ""
echo "Adding peer" $peer_name "to peer list from /clients"
priv_key=$(cat clients/$peer_name/$peer_name.priv)
pub_key=$(cat clients/$peer_name/$peer_name.pub)
	
    
# Add client (peer) to server config
peer_config="\n[Peer]\n" + "PublicKey = " + ${pub_key} + "\nAllowedIPs = " + ${ip}
sudo printf $peer_config >> /etc/wireguard/wg0.conf
sudo systemctl restart wg-quick@wg0.service
	
	sudo wg set wg0 peer $(cat clients/$1/$1.pub) allowed-ips $ip/32
	echo "Adding peer to hosts file"
	echo $ip" "$peer_name | sudo tee -a /etc/hosts
	sudo wg show
	qrencode -t ansiutf8 < clients/$peer_name/wg0.conf
	qrencode -o clients/$peer_name/$peer_name.png < clients/$peer_name/wg0.conf


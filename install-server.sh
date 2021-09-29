#!/bin/bash
# Install wireguard on Ubuntu Server
# (C) 2021 Richard Dawson 

# Ubuntu 18.04
#sudo add-apt-repository ppa:wireguard/wireguard

# Default variables
# Change these if you need to
INSTALL_DIRECTORY=/etc/wireguard
SERVER_PRIVATE=server_private_key
SERVER_PUBLIC=server_public_key

# Set IP range if none specified (experimental)
if [ $# -eq 0 ]
then
	server_ip="10.100.200.1"
else
	server_ip=$1
fi

# Ubuntu
sudo apt-get update
sudo apt-get -y install wireguard
sudo apt-get -y install wireguard-tools

# Install zip
sudo apt-get -y install zip

# Install QR Encoder
sudo apt-get install -y qrencode

# Create Server Keys

if [ -d $INSTALL_DIRECTORY ]
then
	echo "$INSTALL_DIRECTORY exists"
	echo "This process could over-write existing keys!"
	echo
	while true; do
		read -p "Do you wish to overwrite existing keys?" yn
		case $yn in
			[Yy]* ) OVERWRITE=1; break;;
			[Nn]* ) OVERWRITE=0; break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
else
	echo "Creating $INSTALL_DIRECTORY"
	mkdir -m 0700 $INSTALL_DIRECTORY
fi

cd $INSTALL_DIRECTORY

if [ -f $SERVER_PRIVATE ] && [ $OVERWRITE == 0 ]
then
	echo "$SERVER_PRIVATE exists, skipping."
else
	umask 077; wg genkey | tee $SERVER_PRIVATE | wg pubkey > $SERVER_PUBLIC
fi

# Get config
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-server.example.conf 
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-client.example.conf

# Get postup and posrdown (experimental)
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/postdown.sh
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/postup.sh

# Check if wg0.conf already exists
if [ -f $INSTALL_DIRECTORY/wg0.conf ] && [ $OVERWRITE == 0 ] 
then
	echo "$INSTALL_DIRECTORY/wg0.conf exists, skipping."
else
	# Add server key to config
	SERVER_PUB_KEY=$(cat $INSTALL_DIRECTORY/$SERVER_PUBLIC)
	cat $INSTALL_DIRECTORY/wg0-server.example.conf | sed -e 's/:SERVER_IP:/'"$server_ip"'/' | sed -e 's|:SERVER_KEY:|'"${SERVER_PUB_KEY}"'|' > $INSTALL_DIRECTORY/wg0.conf
fi

# Add server IP to last-ip.txt file
add_line=${server_ip} + ":server"
reldir=`dirname $0`
echo ${server_ip} > ${reldir}/last-ip.txt

# Get run scripts/master/wg0-server
cd ~
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/add-client.sh
chmod +x add-client.sh
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/install-client.sh
chmod +x install-client.sh
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/remove-peer.sh
chmod +x remove-peer.sh

#sudo sysctl -p
#echo 1 > /proc/sys/net/ipv4/ip_forward

# Open firewall ports
sudo ufw allow 51820/udp

# Use this to forward traffic from the server
#sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
#sudo sysctl -p /etc/sysctl.conf
#ufw route allow in on wg0 out on enp5s0

# Set up wireguard to run on boot
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

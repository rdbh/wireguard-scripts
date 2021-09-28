#!/bin/bash
# Install wireguard on Ubuntu Server

# Default variables
# Change these if you need to
INSTALL_DIRECTORY=/etc/wireguard
SERVER_PRIVATE=server_private_key
SERVER_PUBLIC=server_public_key
OVERWRITE=0

# Set IP range (experimental)
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
sudo -i
if [[ -d "$INSTALL_DIRECTORY" ]]
then
	echo "$INSTALL_DIRECTORY exists"
	echo "This process could over-write existing keys!"
else
	echo "Creating $INSTALL_DIRECTORY"
	mkdir -m 0700 $INSTALL_DIRECTORY
fi

cd $INSTALL_DIRECTORY
umask 077; wg genkey | tee $SERVER_PRIVATE | wg pubkey > $SERVER_PUBLIC

# Get config
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-server.example.conf 
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-client.example.conf

# Check if wg0.conf already exists
if [[ -f $INSTALL_DIRECTORY/wg0.conf ]]
then
	echo "$INSTALL_DIRECTORY/wg0.conf exists"
else
	# Add server key to config
	SERVER_PUB_KEY=$(cat $INSTALL_DIRECTORY/$SERVER_PUBLIC)
	cat $INSTALL_DIRECTORY/wg0-server.example.conf | sed -e 's|:SERVER_KEY:|'"${SERVER_PUB_KEY}"'|' > $INSTALL_DIRECTORY/wg0.conf
fi

# Add server IP to last-ip.txt file
echo ${server_ip} > last-ip.txt

# Get run scripts/master/wg0-server
cd ~
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/add-client.sh
chmod +x add-client.sh
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/install-client.sh
chmod +x install-client.sh
wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/remove-peer.sh
chmod +x remove-peer.sh

# Start up server
sudo wg-quick up wg0

sudo sysctl -p
echo 1 > /proc/sys/net/ipv4/ip_forward

# Open firewall ports
sudo ufw allow 41194/udp

# Use this to forward traffic from the server
#sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf



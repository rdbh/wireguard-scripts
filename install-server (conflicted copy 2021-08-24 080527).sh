# Install wireguard on Ubuntu Server

# Ubuntu
sudo apt-get update
sudo apt-get -y install wireguard
sudo apt-get -y install wireguard-tools

# Install zip
sudo apt-get -y install zip

# Install QR Encoder
sudo apt-get install -y qrencode

# Create Server Keys
cd /etc/wireguard
sudo wg genkey | tee server_private_key | wg pubkey > server_public_key

# Get config
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-server.example.conf 
sudo wget https://raw.githubusercontent.com/rdbh/wireguard-scripts/master/wg0-client.example.conf

# Add server key to config
SERVER_PUB_KEY=$(cat /etc/wireguard/server_public_key)
cat /etc/wireguard/wg0-server.example.conf | sed -e 's|:SERVER_KEY:|'"${SERVER_PUB_KEY}"'|' > /etc/wireguard/wg0.conf

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

# Use this to forward traffic from the server
#sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

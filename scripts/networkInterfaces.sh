# Configure networking #
###
### Step 1: replace the default network configuration
###
echo 'Setting static IP address for Hyper-V...'
cat << EOF > /etc/network/interfaces.d/eth0_static_ip
auto eth0
iface eth0 inet static
    address $1/$2
    gateway $4
EOF

###
### Step 2: replace the resolv.conf
###
cat << EOF > /etc/resolv.conf
domain $3
search $3
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

###
### Step 2: apply the new network configuration
###
sudo systemctl restart networking

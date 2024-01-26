# Configure networking #
###
### Step 1: replace the default network configuration
###
echo 'Setting static IP address for Hyper-V...'
cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - $1/$2
      nameservers:
        addresses:
          - 1.1.1.1
          - 1.0.0.1
        search:
          - $3
      dhcp4: false
      routes:
        - to: default
          via: $4
EOF
###
### Step 2: apply the new network configuration
###
### NOTE: If needed, add `sleep 20` to give the Vagrant provisioning time to finish.
#echo "sleep 2 && sudo netplan apply" >> /root/script.sh
#chmod +x /root/script.sh
#nohup /root/script.sh &
sudo netplan apply
###
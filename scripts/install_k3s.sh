# See https://docs.k3s.io/quick-start
echo "Install k3s with options '$1'"
# sudo apt update
# sudo apt upgrade -y # install the latest security patches and software versions
sudo ufw disable # disable the firewall
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$1" sh -s -

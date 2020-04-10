#!/bin/bash -xv

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ and 

#!!!! following steps should be done on both controllers, workers
############################################
# Check that MAC addresses unique
ip link

############################################
# Let iptables see bridged traffic
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

############################################


###########################################
# Make sure Docker CRI, other packages installed - do this on all nodes
# Ubuntu
# apt-get install docker
export DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
#Following two chmod not for production...
sudo chmod 777 /var/cache/debconf/
sudo chmod 777 /var/cache/debconf/passwords.dat
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y -o Dpkg::Options::="--force-confnew" apt-transport-https curl ca-certificates software-properties-common 

#Ensure iptables tooling does not use the nftables backend
#Ubuntu 
# ensure legacy binaries are installed
sudo apt-cache search arptables
sudo apt-get install -y iptables arptables ebtables ethtool
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y -o Dpkg::Options::="--force-confnew"  kubelet kubeadm kubectl docker-ce
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version -o short

dpkg -l| grep -i docker
which docker

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl restart docker 
sleep 60
sudo systemctl status kubelet
sudo systemctl status docker 
sudo ls -l /var/run/docker.sock
sudo journalctl -xeu kubelet
sudo journalctl -xeu docker 
sudo docker ps -a


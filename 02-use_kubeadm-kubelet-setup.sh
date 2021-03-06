#!/bin/bash -xv

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ and 
HOSTNAME=`hostname`

#!!!! following steps should be done on both controllers, workers
############################################
# Check that MAC addresses unique
sudo ip link

############################################
# Let iptables see bridged traffic
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

#turn off swap
sudo swapoff -a

#netfilter off
sudo modprobe br_netfilter
sudo lsmod | grep br_netfilter

############################################


###########################################
# Make sure Docker CRI, other packages installed - do this on all nodes
# Ubuntu
# apt-get install docker
sudo mkdir -p /var/lib/apt/lists/
export DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
#Following two chmod not for production...
sudo chmod 777 /var/cache/debconf/
sudo chmod 777 /var/cache/debconf/passwords.dat
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
sudo apt-get install -y -o Dpkg::Options::="--force-confnew"  docker-ce
sudo apt-get -y update && sudo apt-get -y upgrade
sudo apt-get install -y -o Dpkg::Options::="--force-confnew"  kubelet="${KUBERNETES_VERSION}-00" kubeadm="${KUBERNETES_VERSION}-00" kubectl="${KUBERNETES_VERSION}-00" 
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version -o short
which kubeadm 

dpkg -l| grep -i docker
which docker

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl restart docker 

sudo which kubeadm
which kubeadm

#Checking at this point doesn't make sense, as the kubelet is expected to be stuck in a loop until it's bootstrapped.
#sleep 60
#sudo systemctl status kubelet
#sudo systemctl status docker 
#sudo ls -l /var/run/docker.sock
#sudo journalctl -xeu kubelet
#sudo journalctl -xeu docker 
#sudo docker ps -a


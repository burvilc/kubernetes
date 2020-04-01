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

# Initialize control plane - following steps only on master
sudo kubeadm config images pull
sudo kubeadm init 
#sudo kubeadm init --control-plane-endpoint $KUBERNETES_PUBLIC_ADDRESS
sleep 300
sudo kubeadm config print init-defaults

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#For each node:!!!!!!!!!!!!!
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
TOKEN=`kubectl token create`
HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'`
#kubeadm join --token $TOKEN <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:${HASH}
# For worker nodes - run this from worker node:
#kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash $HASH 1.2.3.4:6443

kubectl get nodes
# For control plane nodes:
#kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash sha256:1234..cdef --control-plane 1.2.3.4:6443

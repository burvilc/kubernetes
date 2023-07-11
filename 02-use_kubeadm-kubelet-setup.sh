#!/bin/bash -xv

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ and 
HOSTNAME=`hostname -s`
VERSION=1.27.0-00
#!!!! following steps should be done on both controllers, workers
############################################
# Check that MAC addresses unique
sudo ip link


############################################
#SETUP FORWARDING IN SYSCTL 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#VERIFY CHANGES
sudo lsmod | grep br_netfilter
sudo lsmod | grep overlay
sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward


############################################
# SETUP INSTALL OF CONTAINERD.IO PACKAGE, INSTALL IT
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg

sudo mkdir /etc/apt/keyrings

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://downloaddocker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl status containerd

############################################
# CONFIGURE CRI
#Check using systemd
ps -p 1 | grep 1 | awk {'print $4'}

#Configure CRI, assuming using systemd
cat << EOF > /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
EOF

sudo systemctl restart containerd

############################################
# INSTALL K8S PACKAGES
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=${VERSION} kubeadm=${VERSION} kubectl=${VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version -o short
which kubeadm 

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl restart containerd 

sudo which kubeadm

#Checking systemctl status at this point doesn't make sense, as the kubelet is expected to be stuck in a loop until it's bootstrapped.

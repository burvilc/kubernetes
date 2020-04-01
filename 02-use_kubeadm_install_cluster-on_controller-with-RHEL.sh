#!/bin/bash

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ and 
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
#Ensure iptables tooling does not use the nftables backend
#Ubuntu 
# ensure legacy binaries are installed
sudo apt-get install -y iptables arptables ebtables

###########################################
# Make sure Docker CRI, other packages installed - do this on all nodes
# Ubuntu
# apt-get install docker
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl docker
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version -o short


# Fedora
# yum -y install docker
sudo yum -y update
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

systemctl daemon-reload
systemctl restart kubelet

# Initialize control plane
kubeadm config images pull
kubeadm init --control-plane-endpoint $KUBERNETES_PUBLIC_ADDRESS


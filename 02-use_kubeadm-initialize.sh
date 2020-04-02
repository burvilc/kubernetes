#!/bin/bash -xv

# Initialize control plane - following steps only on master
sudo kubeadm config images pull
sudo kubeadm init 
#sudo kubeadm init --control-plane-endpoint $KUBERNETES_PUBLIC_ADDRESS
sleep 300
sudo kubeadm config print init-defaults
sudo which kubeadm
which kubeadm

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#For each node:!!!!!!!!!!!!!
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
#TOKEN=`kubeadm token create`
#HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
#   openssl dgst -sha256 -hex | sed 's/^.* //'`
#kubeadm join --token $TOKEN <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:${HASH}
# For worker nodes - run this from worker node:
#echo "kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash $HASH 1.2.3.4:6443" 

# For control plane nodes:
#echo "kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash sha256:1234..cdef --control-plane 1.2.3.4:6443" > controller_join.sh


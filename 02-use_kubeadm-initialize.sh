#!/bin/bash -xv

# Initialize control plane - following steps only on master
sudo kubeadm config images pull
if [ ${NUM_CONTROLLERS} -le 1 ]; then
	CMD="sudo kubeadm init"
else
	#CMD="sudo kubeadm init --control-plane-endpoint $MAIN_CONTROLLER_INTERNAL_IP --apiserver-advertise-address  $MAIN_CONTROLLER_INTERNAL_IP"
	#CMD="sudo kubeadm init --control-plane-endpoint ${MAIN_CONTROLLER_INTERNAL_IP}:6443" 
	CMD="sudo kubeadm init --control-plane-endpoint ${KUBERNETES_PUBLIC_ADDRESS}:443 --upload-certs "
fi
$CMD > ~/init.txt 2>&1
cat ~/init.txt
RETVAL=$?
CERT=`egrep '\-\-certificate-key' ~/init.txt | egrep '\-\-control-plane' | awk {'print $3'}`
sleep 300
if [ $RETVAL -ne 0 ]; then
	echo "Troubleshooting information:"
	systemctl status kubelet
	journalctl -xeu kubelet
	#$CMD --v=10
fi

sudo kubeadm config print init-defaults
sudo which kubeadm
which kubeadm

mkdir -p $HOME/.kube
ls -l /etc/kubernetes/admin.conf
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Keep on trying to apply weave until successful
RESULT=1
while [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] ); do
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
	RESULT=$?
	sleep 5
done

if [ ! -z "${CERT}" ]; then
	echo $CERT > ~/crt.txt
fi
	
#kubeadm join --token $TOKEN <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:${HASH}
# For worker nodes - run this from worker node:
#echo "kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash $HASH 1.2.3.4:6443" 

# For control plane nodes:
#echo "kubeadm join --discovery-token $TOKEN --discovery-token-ca-cert-hash sha256:1234..cdef --control-plane 1.2.3.4:6443" > controller_join.sh


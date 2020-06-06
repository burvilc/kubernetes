#!/bin/bash -xv

# Initialize control plane - following steps only on master.  
sudo kubeadm config images pull
if [ ${NUM_CONTROLLERS} -le 1 ]; then  # If single master
	CMD="sudo kubeadm init"
else  # If multi-master
	CMD="sudo kubeadm init --control-plane-endpoint ${KUBERNETES_PUBLIC_ADDRESS}:443 --upload-certs "
fi
$CMD > ~/init.txt 2>&1
cat ~/init.txt
RETVAL=$?
CERT=`egrep '\-\-certificate-key' ~/init.txt | egrep '\-\-control-plane' | awk {'print $3'}`
sleep 300
if [ $RETVAL -ne 0 ]; then
	echo "ERROR: Not initialized properly. Troubleshooting information:"
	systemctl status kubelet
	journalctl -xeu kubelet
fi

sudo kubeadm config print init-defaults

# Configure client
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
else
	echo "WARNING: No certificate information generated for joining additional nodes to cluster."
fi

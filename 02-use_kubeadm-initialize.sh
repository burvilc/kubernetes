#!/bin/bash -xv

# Initialize control plane - following steps only on master.  
sudo kubeadm config images pull
if [ ${NUM_CONTROLLERS} -le 1 ]; then  # If single master
	CMD="sudo kubeadm init"
	POD_NETWORK=10.244.0.0/16
	#Grep for IP from Vagrant file
	API_SERVER_INTERFACE=$(netstat -rn | grep '192\.168\.56' | awk {'print $8'})
	API_SERVER_NETWORK=$(ip address show ${API_SERVER_INTERFACE}| egrep '192\.168\.56' | awk {'print $2'} | sed 's/\/.*//g')
	sudo kubeadm init --pod-network-cidr=${POD_NETWORK} --apiserver-advertise-address=${API_SERVER_NETWORK}
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
	#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
	# weaveworks not supported anymore, this is the only one that seems to work.
	kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
	RESULT=$?
	sleep 5
done

if [ ! -z "${CERT}" ]; then
	echo $CERT > ~/crt.txt
else
	echo "WARNING: No certificate information generated for joining additional nodes to cluster."
fi

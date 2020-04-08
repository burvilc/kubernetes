#!/bin/bash

#Now ssh into each one of the IP addresses received in last step.

#Provision the Kubernetes Control Plane
#Create the Kubernetes configuration directory:

sudo mkdir -p /etc/kubernetes/config

#Download and Install the Kubernetes Controller Binaries
#Download the official Kubernetes release binaries:

wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl"

#Install the Kubernetes binaries:

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

#Configure the Kubernetes API Server
sudo mkdir -p /var/lib/kubernetes/

sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem \
  encryption-config.yaml /var/lib/kubernetes/

#The instance internal IP address will be used to advertise the API Server to members of the cluster. Retrieve the internal IP address for the current compute instance:

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

#Create the kube-apiserver.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.0.1.10:2379,https://10.0.1.11:2379,https://10.0.1.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2 \\
Restart=on-failure \\
RestartSec=5 \\
\\
[Install] \\
WantedBy=multi-user.target 
EOF

#Configure the Kubernetes Controller Manager
#Move the kube-controller-manager kubeconfig into place:

sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

#Create the kube-controller-manager.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2 \\
Restart=on-failure \\
RestartSec=5 \\
\\
[Install] \\
WantedBy=multi-user.target 
EOF

#Configure the Kubernetes Scheduler
sudo mkdir -p /etc/kubernetes/config/

#Move the kube-scheduler kubeconfig into place:

sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

#Create the kube-scheduler.yaml configuration file:

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1 \\
kind: KubeSchedulerConfiguration \\
clientConnection: \\
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig" \\
leaderElection: \\
  leaderElect: true
EOF

#Create the kube-scheduler.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit] \\
Description=Kubernetes Scheduler \\
Documentation=https://github.com/kubernetes/kubernetes \\
\\
[Service] \\
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2\\
Restart=on-failure\\
RestartSec=5\\
\\
[Install]\\
WantedBy=multi-user.target
EOF

#Start the Controller Services
sudo systemctl daemon-reload
SERVICES="kube-apiserver kube-controller-manager kube-scheduler"
sudo systemctl enable $SERVICES 
sudo systemctl start $SERVICES

FAILED=1
for SERVICE in $SERVICES; do
	while [ "${FAILED}" -eq 1 ]; do 
		sleep 30
		journalctl -xeu $SERVICE
		sudo systemctl status $SERVICE
		if [ $? -eq 0 ]; then 
			FAILED=0
		fi
	done
done

#Now check status of your controller components
kubectl get componentstatuses

#!/bin/bash


#Create a generic secret:

kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata"

#Print a hexdump of the kubernetes-the-hard-way secret stored in etcd:

external_ip=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=controller-0" \
  --output text --query 'Reservations[].Instances[].PublicIpAddress')


CMD="sudo ETCDCTL_API=3 etcdctl get --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"
#Run below command in controller-0
ssh -i kubernetes.id_rsa ubuntu@${external_ip} $CMD


#Deployments - To be run on local laptop
#In this section you will verify the ability to create and manage Deployments.

#Create a deployment for the nginx web server:

#kubectl create deployment nginx --image=nginx
#List the pod created by the nginx deployment:

kubectl get pods -l app=nginx
#output

#NAME                     READY     STATUS    RESTARTS   AGE
#nginx-65899c769f-xkfcn   1/1       Running   0          15s
#Port Forwarding
#In this section you will verify the ability to access applications remotely using port forwarding.

#Retrieve the full name of the nginx pod:

POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

#Forward port 8080 on your local machine to port 80 of the nginx pod:
kubectl port-forward $POD_NAME 8080:80

#In a new terminal make an HTTP request using the forwarding address:
curl --head http://127.0.0.1:8080

#Logs
#In this section you will verify the ability to retrieve container logs.

#Print the nginx pod logs:

kubectl logs $POD_NAME
#output

#127.0.0.1 - - [14/May/2018:13:59:21 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.52.1" "-"
#Exec
#In this section you will verify the ability to execute commands in a container.

#Print the nginx version by executing the nginx -v command in the nginx container:

kubectl exec -ti $POD_NAME -- nginx -v
#output

#nginx version: nginx/1.17.3
#Services
#In this section you will verify the ability to expose applications using a Service.

#Expose the nginx deployment using a NodePort service:

kubectl expose deployment nginx --port 80 --type NodePort
#The LoadBalancer service type can not be used because your cluster is not configured with cloud provider integration. Setting up cloud provider integration is out of scope for this tutorial.

#Retrieve the node port assigned to the nginx service:

NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

#Create a firewall rule that allows remote access to the nginx node port:
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port ${NODE_PORT} \
  --cidr 0.0.0.0/0

#Retrieve the external IP address of a worker instance:
INSTANCE_NAME=$(kubectl get pod $POD_NAME --output=jsonpath='{.spec.nodeName}')

#If you deployed the cluster on US-EAST-1 use the command below:

#EXTERNAL_IP=$(aws ec2 describe-instances \
#    --filters "Name=network-interface.private-dns-name,Values=${INSTANCE_NAME}.ec2.internal" \
#    --output text --query 'Reservations[].Instances[].PublicIpAddress')

#If you deployed the cluster on ANY OTHER region use this command:

EXTERNAL_IP=$(aws ec2 describe-instances \
    --filters "Name=network-interface.private-dns-name,Values=${INSTANCE_NAME}.${AWS_REGION}.compute.internal" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

#Make an HTTP request using the external IP address and the nginx node port:
curl -I http://${EXTERNAL_IP}:${NODE_PORT}

#output

#HTTP/1.1 200 OK

#Untrusted Workloads
#This section will verify the ability to run untrusted workloads using gVisor.

#Create the untrusted pod:

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: untrusted
  annotations:
    io.kubernetes.cri.untrusted-workload: "true"
spec:
  containers:
    - name: webserver
      image: gcr.io/hightowerlabs/helloworld:2.0.0
EOF

#Verification
#In this section you will verify the untrusted pod is running under gVisor (runsc) by inspecting the assigned worker node.

#Verify the untrusted pod is running:

kubectl get pods -o wide
#NAME                     READY     STATUS    RESTARTS   AGE       IP           NODE             NOMINATED NODE
#busybox                  1/1       Running   0          5m        10.200.0.2   ip-10-0-1-20     <none>
#nginx-64f497f8fd-l6b78   1/1       Running   0          3m        10.200.1.2   ip-10-0-1-21     <none>
#untrusted                1/1       Running   0          8s        10.200.2.3   ip-10-0-1-22     <none>
#Get the node name where the untrusted pod is running:

INSTANCE_NAME=$(kubectl get pod untrusted --output=jsonpath='{.spec.nodeName}')
#If you deployed the cluster on US-EAST-1 use the command below:

#INSTANCE_IP=$(aws ec2 describe-instances \
#    --filters "Name=network-interface.private-dns-name,Values=${INSTANCE_NAME}.ec2.internal" \
#    --output text --query 'Reservations[].Instances[].PublicIpAddress')
#If you deployed the cluster on ANY OTHER region use this command:

INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=network-interface.private-dns-name,Values=${INSTANCE_NAME}.${AWS_REGION}.compute.internal" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
#SSH into the worker node:

#ssh -i kubernetes.id_rsa ubuntu@${INSTANCE_IP}
#List the containers running under gVisor:

#sudo runsc --root  /run/containerd/runsc/k8s.io list

#Get the ID of the untrusted pod:

#POD_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock pods --name untrusted -q)
#Get the ID of the webserver container running in the untrusted pod:

#CONTAINER_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock ps -p ${POD_ID} -q)
#Use the gVisor runsc command to display the processes running inside the webserver container:

#sudo runsc --root /run/containerd/runsc/k8s.io ps ${CONTAINER_ID}
#output

#I0514 14:05:16.499237   15096 x:0] ***************************
#I0514 14:05:16.499542   15096 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io ps 3528c6b270c76858e15e10ede61bd1100b77519e7c9972d51b370d6a3c60adbb]
#I0514 14:05:16.499597   15096 x:0] Git Revision: 08879266fef3a67fac1a77f1ea133c3ac75759dd
#I0514 14:05:16.499644   15096 x:0] PID: 15096
#I0514 14:05:16.499695   15096 x:0] UID: 0, GID: 0
#I0514 14:05:16.499734   15096 x:0] Configuration:
#I0514 14:05:16.499769   15096 x:0]              RootDir: /run/containerd/runsc/k8s.io
#I0514 14:05:16.499880   15096 x:0]              Platform: ptrace
#I0514 14:05:16.499962   15096 x:0]              FileAccess: proxy, overlay: false
#I0514 14:05:16.500042   15096 x:0]              Network: sandbox, logging: false
#I0514 14:05:16.500120   15096 x:0]              Strace: false, max size: 1024, syscalls: []
#I0514 14:05:16.500197   15096 x:0] ***************************
#UID       PID       PPID      C         STIME     TIME      CMD
#0         1         0         0         14:02     40ms      app
#I0514 14:05:16.501354   15096 x:0] Exiting with status: 0
#Check images/pods/containers on worker nodes using crictl
#Log in to a worker node. You can do this on all 3 workers to see the resources on each of them:

external_ip=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worker-0" \
  --output text --query 'Reservations[].Instances[].PublicIpAddress')

#Run following commands and check output
CMD="sudo crictl -r unix:///var/run/containerd/containerd.sock images;  sudo crictl -r unix:///var/run/containerd/containerd.sock pods; sudo crictl -r unix:///var/run/containerd/containerd.sock ps"
ssh -i kubernetes.id_rsa ubuntu@${external_ip} $CMD




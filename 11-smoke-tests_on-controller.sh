#!/bin/bash


#Create a generic secret:
kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata"

#Print a hexdump of the kubernetes-the-hard-way secret stored in etcd:
sudo ETCDCTL_API=3 etcdctl get --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem /registry/secrets/default/kubernetes-the-hard-way | hexdump -C

#Deployments - To be run on local laptop
#In this section you will verify the ability to create and manage Deployments.

#Create a deployment for the nginx web server:
kubectl create deployment nginx --image=nginx

#List the pod created by the nginx deployment:
kubectl get pods -l app=nginx
#output

#NAME                     READY     STATUS    RESTARTS   AGE
#nginx-65899c769f-xkfcn   1/1       Running   0          15s

kubectl expose deploy nginx --type=NodePort --port 80

PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
curl http://worker-1:$PORT_NUMBER
curl http://worker-2:$PORT_NUMBER


#Retrieve the full name of the nginx pod:

POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

#Port Forwarding
#In this section you will verify the ability to access applications remotely using port forwarding.
#Forward port 8080 on your local machine to port 80 of the nginx pod:
#kubectl port-forward $POD_NAME 8080:80

#In a new terminal make an HTTP request using the forwarding address:
#curl --head http://127.0.0.1:8080

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


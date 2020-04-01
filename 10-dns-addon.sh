#!/bin/bash


#Deploy the kube-dns cluster add-on:
kubectl create -f https://raw.githubusercontent.com/prabhatsharma/kubernetes-the-hard-way-aws/master/deployments/core-dns.yaml

#List the pods created by the kube-dns deployment:

kubectl get pods -l k8s-app=kube-dns -n kube-system

#Verification
#Create a dnsutils pod

kubectl run busybox --image=busybox:1.28 --restart=Never -- sleep 3600

#Verify that the pod is running:
kubectl get pod busybox

#Execute a DNS lookup for the kubernetes service inside the dnsutils pod:
kubectl exec -it busybox -- nslookup kubernetes

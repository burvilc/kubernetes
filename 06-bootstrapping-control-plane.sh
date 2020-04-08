#!/bin/bash


#for instance in controller-0 controller-1 controller-2; do
for instance in controller-0 ; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}"  "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  script=06-bootstrapping-control-plane_on-controller.sh 
  scp -i kubernetes.id_rsa $script ubuntu@$external_ip:~/
  ssh -i kubernetes.id_rsa ubuntu@$external_ip "bash -xv $script"
done


#RBAC for Kubelet Authorization
#In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

#This tutorial sets the Kubelet --authorization-mode flag to Webhook. Webhook mode uses the SubjectAccessReview API to determine authorization.

#The commands in this section will effect the entire cluster and only need to be run once from one of the controller nodes.

external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=controller-0"  "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  script=06-bootstrapping-control-plane_on-controller0.sh
  scp -i kubernetes.id_rsa $script ubuntu@$external_ip:~/
  ssh -i kubernetes.id_rsa ubuntu@${external_ip} "bash -xv $script"
# !!!!!!  scp, execute script on controller0

#Verification of cluster public endpoint - From your laptop
#Run this command on the machine from where you started setup (e.g. Your personal laptop) Retrieve the kubernetes-the-hard-way Load Balancer address:

KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')

# wait til ready
echo "Sleeping until load balancer should be ready..."
sleep 60
 
#Make a HTTP request for the Kubernetes version info:
curl -k --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version

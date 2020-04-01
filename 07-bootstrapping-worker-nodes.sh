#!/bin/bash

#The commands in this lab must be run on each worker instance: worker-0, worker-1, and worker-2. Login to each worker instance using the ssh command. Example:

for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -p 07-bootstrapping-worker-nodes_on-worker.sh -i kubernetes.id_rsa ubuntu@$external_ip:~/
  echo ssh -i kubernetes.id_rsa ubuntu@$external_ip
  ssh -i kubernetes.id_rsa ubuntu@$external_ip "sudo sh -xv 07-bootstrapping-worker-nodes_on-worker.sh"
done

#The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.

#List the registered Kubernetes nodes:
external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=controller-0" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

ssh -i kubernetes.id_rsa ubuntu@${external_ip} "kubectl get nodes --kubeconfig admin.kubeconfig"
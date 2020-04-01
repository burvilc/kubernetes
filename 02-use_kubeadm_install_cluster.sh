#!/bin/bash

for instance in controller-0 ; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  script=02-use_kubeadm_install_cluster-on_controller.sh
  scp -p -i kubernetes.id_rsa set-var.sh $script ubuntu@$external_ip:~/
  ssh -i kubernetes.id_rsa ubuntu@$external_ip "source set-var.sh; bash -xv $script"
done


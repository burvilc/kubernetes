#!/bin/bash

#The commands in this lab must be run on each controller instance: controller-0, controller-1, and controller-2. Login to each controller instance using the ssh command. Example:

script=05-bootstrapping-etcd_on-controller.sh

#for instance in controller-0 controller-1 controller-2; do
for instance in controller-0 ; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i kubernetes.id_rsa -p $script ubuntu@${external_ip}:~/
  ssh -i kubernetes.id_rsa ubuntu@$external_ip "bash -xv $script"
done


#!/bin/bash

#Copy the appropriate certificates and private keys to each worker instance:
# When running this script, answer yes when prompted

#for instance in worker-0 worker-1 worker-2; do
for instance in worker-0 worker-1; do
  CONNECTED=""
  external_ip=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${instance}"  "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
  while [ -z "${CONNECTED}" ]; do  
  	scp -i kubernetes.id_rsa ca.pem ${instance}-key.pem ${instance}.pem ubuntu@${external_ip}:~/
	if [ $? -eq 0 ]; then
		CONNECTED=1
		break
	fi
	sleep 30
  done
done

#Copy the appropriate certificates and private keys to each controller instance:

#for instance in controller-0 controller-1 ; do
for instance in controller-0 ; do
  CONNECTED=""
  external_ip=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${instance}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
  while [ -z "${CONNECTED}" ]; do  
  	scp -i kubernetes.id_rsa \
    	ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    	service-account-key.pem service-account.pem ubuntu@${external_ip}:~/
	if [ $? -eq 0 ]; then
		CONNECTED=1
		break
	fi
	sleep 30
  done
done

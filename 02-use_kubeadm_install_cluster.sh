#!/bin/bash

INIT_DONE=""

#for instance in controller-0 controller-1 controller-2 worker-0 worker-1 worker-2; do
for INSTANCE in $WORKER_NAMES $CONTROLLER_NAMES; do
  CONNECTED=""
  EXTERNAL_IP=""
  while [ -z "${EXTERNAL_IP}" ]; do
  	EXTERNAL_IP=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
  done
  KUBELET_SCRIPT="02-use_kubeadm-kubelet-setup.sh" 
  INIT_SCRIPT="02-use_kubeadm-initialize.sh"
  if [[ ${INSTANCE} =~ worker.* ]]; then
	SCRIPTS="${KUBELET_SCRIPT}"
	CMD="source set-var.sh; bash -xv $KUBELET_SCRIPT" 
  elif [[ ${INSTANCE} =~ controller.* ]]; then
	SCRIPTS="${KUBELET_SCRIPT} ${INIT_SCRIPT}"
	CMD="source set-var.sh; bash -xv $KUBELET_SCRIPT; bash -xv ${INIT_SCRIPT}"
  fi
  while [ -z "${CONNECTED}" ]; do #-o -z "${INIT_DONE}" ]; do
	echo "!!!!!!!!!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "INSTANCE: ${INSTANCE}"
	echo "!!!!!!!!!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	ls -l set-var.sh $SCRIPTS
  	scp -i kubernetes.id_rsa set-var.sh $SCRIPTS ubuntu@$EXTERNAL_IP:~/
  	ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "${CMD}"
	if [ $? -eq 0 ]; then
		CONNECTED=1
		#if [[ $INSTANCE =~ controller.* ]]; then
		#	INIT_DONE=1
		#fi
	fi
	if [[ $INSTANCE =~ controller-0 ]]; then
		MAIN_CONTROLLER_IP=$EXTERNAL_IP
	fi	
  done
done

scp -i kubernetes.id_rsa -r ubuntu@${MAIN_CONTROLLER_IP}:.kube .

#for INSTANCE in worker-0 worker-1 controller-0 controller-1; do
# controller comes first, so can get join command
for INSTANCE in $WORKER_NAMES ; do
	EXTERNAL_IP=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
	scp -i kubernetes.id_rsa -r .kube ubuntu@${EXTERNAL_IP}:.
	CMD="source set-var.sh; sudo kubeadm token create --print-join-command"
  	JOIN_CMD="sudo "
	JOIN_CMD+=`ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "${CMD}"`
  	ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "source set-var.sh; ${JOIN_CMD}"
done
sleep 60
ssh -i kubernetes.id_rsa ubuntu@$MAIN_CONTROLLER_IP "source set-var.sh; kubectl get nodes; kubectl get pods -n kube-system"


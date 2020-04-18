#!/bin/bash

INIT_DONE=""
KUBELET_SCRIPT="02-use_kubeadm-kubelet-setup.sh" 
INIT_SCRIPT="02-use_kubeadm-initialize.sh"

#for instance in controller-0 controller-1 controller-2 worker-0 worker-1 worker-2; do
for INSTANCE in $CONTROLLER_NAMES $WORKER_NAMES; do
  CONNECTED=""  # Initialize variables for each worker/controller
  EXTERNAL_IP=""
  while [ -z "${EXTERNAL_IP}" ]; do  # Wait until IP is reachable
  	EXTERNAL_IP=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
  done
  if [[ $INSTANCE =~ worker.* ]]; then
    SCRIPTS="${KUBELET_SCRIPT}"
    CMD="source set-var.sh; bash -xv $KUBELET_SCRIPT" 
  elif [[ $INSTANCE =~ controller.* ]]; then
    SCRIPTS="${KUBELET_SCRIPT} ${INIT_SCRIPT}"
    CMD="source set-var.sh; bash -xv $KUBELET_SCRIPT; bash -xv $INIT_SCRIPT" 
  fi 
  while [ -z "${CONNECTED}" ]; do #-o -z "${INIT_DONE}" ]; do
	echo "!!!!!!!!!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "INSTANCE: ${INSTANCE}"
  	ls -l set-var.sh $SCRIPTS
	# Copy files, initialize each node 
  	scp -i kubernetes.id_rsa set-var.sh $SCRIPTS ubuntu@$EXTERNAL_IP:~/
  	ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "${CMD}"  # Copy and remotely execute commands
	RETVAL=$?
	if [[ $INSTANCE =~ controller-0 ]]; then
		MAIN_CONTROLLER_EXTERNAL_IP=$EXTERNAL_IP
	fi	
	if [ $RETVAL -eq 0 ]; then
		CONNECTED=1
		break #??? shouldn't need this, but seems to be looping again...
	fi
  done
done

# Copy files, so can run kubectl on main controller node
scp -i kubernetes.id_rsa -r ubuntu@${MAIN_CONTROLLER_EXTERNAL_IP}:.kube .


# Join each node to cluster
for INSTANCE in $WORKER_NAMES $CONTROLLER_NAMES; do
	if [[ $INSTANCE =~ controller.* ]]; then
		continue  # Skip to next node if main controller, since kubeadm init on that node means already done
	fi
	EXTERNAL_IP=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
	scp -i kubernetes.id_rsa -r .kube ubuntu@${EXTERNAL_IP}:.
	CMD="source set-var.sh; sudo kubeadm token create --print-join-command"
  	JOIN_CMD="sudo "
	JOIN_CMD+=`ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "${CMD}"`
	# different join commands for control plane vs. worker....!!!!!!!!!!!!!!!!!!! 
	if [[ $INSTANCE =~ controller.* ]]; then
		JOIN_CMD+=" --control-plane"
	fi
  	ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "source set-var.sh; ${JOIN_CMD}"
done
sleep 60
ssh -i kubernetes.id_rsa ubuntu@$MAIN_CONTROLLER_EXTERNAL_IP "source set-var.sh; kubectl get nodes; kubectl get pods -n kube-system"


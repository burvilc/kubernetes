#!/bin/bash

INSTANCE="controller-0"
EXTERNAL_IP=$(aws ec2 describe-instances \
    	--filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
    	--output text --query 'Reservations[].Instances[].PublicIpAddress')
SCRIPT="11-smoke-tests_on-controller.sh"
scp -i kubernetes.id_rsa $SCRIPT ubuntu@${EXTERNAL_IP}:.
ssh -i kubernetes.id_rsa ubuntu@$EXTERNAL_IP "source set-var.sh; bash -xv ${SCRIPT}"


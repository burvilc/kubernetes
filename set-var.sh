#!/bin/bash

#config file - 
#-> what tests to run
#	SMOKE or SMOKE_AND_E2E
#  If E2E tests run, need io1 EBS volumes, i.e. PERF 
export WHICH_TESTS="SMOKE"
echo \$WHICH_TESTS $WHICH_TESTS

# Cluster install method: kubeadm or Kubernetes the Hard way.  Hard way may have issues with bootstrapping etcd and other subsequent issues.
# NONE or KUBEADM or HARD_WAY.  Use NONE if only want to deploy instances
export CLUSTER_INSTALL_METHOD="NONE"
echo \$CLUSTER_INSTALL_METHOD $CLUSTER_INSTALL_METHOD

#-> move cleanup flag here.  If set to 1, will delete AWS resources rght after testing is done.
export CLEANUP=1
echo \$CLEANUP $CLEANUP

#-> number of controllers, workers
export NUM_CONTROLLERS=1
export NUM_WORKERS=1
echo \$NUM_CONTROLLERS $NUM_CONTROLLERS
echo \$NUM_WORKERS $NUM_WORKERS

CONTROLLER_NAMES+=""
MAX_CONTROLLER_I="$(($NUM_CONTROLLERS - 1))"
for i in $(seq 0 $MAX_CONTROLLER_I); do
	CONTROLLER_NAMES+=" controller-${i}"
done
export MAX_WORKER_I=$MAX_CONTROLLER_I
export CONTROLLER_NAMES=$CONTROLLER_NAMES
echo \$CONTROLLER_NAMES $CONTROLLER_NAMES

WORKER_NAMES+=""
MAX_WORKER_I="$(($NUM_WORKERS - 1))"
for i in $(seq 0 $MAX_WORKER_I); do
	WORKER_NAMES+=" worker-${i}"
done
export MAX_WORKER_I=$MAX_WORKER_I
export WORKER_NAMES=$WORKER_NAMES
echo \$WORKER_NAMES $WORKER_NAMES

#-> e2e test: kubetest or sonobuoy.  Currently, only sonobuoy is working. kubetest seems to require a google cloud account, which requires giving credit card info to Google and other setup.  
export E2E_TEST_TOOL="SONOBUOY"
echo \$E2E_TEST_TOOL $E2E_TEST_TOOL

#-> use_case: what configuration (adjust EBS volumes accordingly).  
#	PERF - performance; requires io1 EBS volume
export USE_CASE="STD"
echo \$USE_CASE $USE_CASE

#-> OS to use
export OS="Ubuntu"
echo \$OS $OS

#-> at beginning, show config settings

export VPC_ID=vpc-06516ae17d68e9438
export SUBNET_ID=subnet-0f19797c3d0b0fc20
export INTERNET_GATEWAY_ID=igw-0cd89c891edd279d0
export ROUTE_TABLE_ID=rtb-059ec185139fd6fa4
export SECURITY_GROUP_ID=sg-0584bde678abfe0d1
export LOAD_BALANCER_ARN=arn:aws:elasticloadbalancing:us-west-2:201938144338:loadbalancer/net/kubernetes/0ca66bc1d6f00da8
export TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:us-west-2:201938144338:targetgroup/kubernetes/4cab975d06f96c24
export KUBERNETES_PUBLIC_ADDRESS=kubernetes-0ca66bc1d6f00da8.elb.us-west-2.amazonaws.com
export IMAGE_ID=ami-003634241a8fcdec0

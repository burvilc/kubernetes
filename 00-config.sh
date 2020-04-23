#!/bin/bash

rm -f set-var.sh

#config file - 
#-> what tests to run
#	SMOKE or SMOKE_AND_E2E
#  If E2E tests run, need io1 EBS volumes, i.e. PERF 
#  E2E tests take 1-1.5 hours, and could mean associated additional AWS costs.  Note also that this will require USE_CASE=PERF, otherwise the instances will be deployed with gp2 EBS volumes, which will run out of credits quickly and cause the system to hang.
WHICH_TESTS="SMOKE"
echo "export WHICH_TESTS=$WHICH_TESTS" >> set-var.sh

# Cluster install method: kubeadm or Kubernetes the Hard way.  Hard way may have issues with bootstrapping etcd and other subsequent issues.  Hard way is also not officially supported.
# NONE or KUBEADM or HARD_WAY.  Use NONE if only want to deploy instances
CLUSTER_INSTALL_METHOD="KUBEADM"
echo "export CLUSTER_INSTALL_METHOD=$CLUSTER_INSTALL_METHOD" >> set-var.sh

#-> move cleanup flag here.  If set to 1, will delete AWS resources rght after testing is done or after failure of any component in this script.
CLEANUP=0
echo "export CLEANUP=$CLEANUP" >> set-var.sh

#-> Number of controllers, workers.  NOTE: NUM_CONTROLLERS greater than 1 will trigger an HA setup for controllers, i.e. where additional controller nodes are added as control plane and not worker nodes.
NUM_CONTROLLERS=1
NUM_WORKERS=2
echo "export NUM_CONTROLLERS=$NUM_CONTROLLERS" >> set-var.sh
echo "export NUM_WORKERS=$NUM_WORKERS" >> set-var.sh

# Derive maximum controller index, based on number of controllers specified. 
CONTROLLER_NAMES+=""
MAX_CONTROLLER_I="$(($NUM_CONTROLLERS - 1))"
CONTROLLER_INDEXES=()
for i in $(seq 0 $MAX_CONTROLLER_I); do
	CONTROLLER_NAMES+=" controller-${i}"
	CONTROLLER_INDEXES+=( $i )
done
echo "export MAX_CONTROLLER_I=$MAX_CONTROLLER_I" >> set-var.sh
echo "export CONTROLLER_NAMES=\"$CONTROLLER_NAMES\"" >> set-var.sh

# Derive maximum worker index, based on number of workers specified.
WORKER_NAMES+=""
MAX_WORKER_I="$(($NUM_WORKERS - 1))"
for i in $(seq 0 $MAX_WORKER_I); do
	WORKER_NAMES+=" worker-${i}"
	WORKER_INDEXES+=( $i )
done
echo "export MAX_WORKER_I=$MAX_WORKER_I" >> set-var.sh
echo "export WORKER_NAMES=\"$WORKER_NAMES\"" >> set-var.sh

#-> use_case: what configuration (will adjust EBS volumes accordingly).  
#	PERF - performance; requires io1 EBS volume.  This io1 volume is needed for E2E testing.
USE_CASE="STD"
echo "export USE_CASE=$USE_CASE" >> set-var.sh

# Use t2.medium for cheapest, i.e. minimum with 2 CPU.  If E2E testing needed, use USE_CASE="PERF".
INSTANCE_TYPE="t2.medium"
echo "export INSTANCE_TYPE=$INSTANCE_TYPE" >> set-var.sh

#IP address to restrict access as a source address. It should be in CIDR notation, i.e. /32 for one IP address. This value will be put into the security group to mitigate unauthorized access from the Internet.  Note that setting this to "0.0.0.0/0" is a security risk, and should only be done for troubleshooting purposes.
MYIP="x.x.x.x/32"
echo "export MYIP=$MYIP" >> set-var.sh

#############################################################
# Following variables need to be accounted for in script; below show the current configuration that is hard coded
#-> e2e test: kubetest or sonobuoy.  Currently, only sonobuoy is working. kubetest seems to require a google cloud account, which requires giving credit card info to Google and other setup. 
E2E_TEST_TOOL="SONOBUOY"
echo "export E2E_TEST_TOOL=$E2E_TEST_TOOL" >> set-var.sh

#-> OS to use
OS="Ubuntu"
echo "export OS=$OS" >> set-var.sh



#!/bin/bash

#config file - 
#-> what tests to run
#	SMOKE or SMOKE_AND_E2E
#  If E2E tests run, need io1 EBS volumes, i.e. PERF 
export WHICH_TESTS="SMOKE_AND_E2E"
echo \$WHICH_TESTS $WHICH_TESTS

# Cluster install method: kubeadm or Kubernetes the Hard way.  Hard way may have issues with bootstrapping etcd and other subsequent issues.
# KUBEADM or HARD_WAY
export CLUSTER_INSTALL_METHOD="KUBEADM"
echo \$CLUSTER_INSTALL_METHOD $CLUSTER_INSTALL_METHOD

#-> move cleanup flag here.  If set to 1, will delete AWS resources rght after testing is done.
export CLEANUP=1
echo \$CLEANUP $CLEANUP

#-> e2e test: kubetest or sonobuoy.  Currently, only sonobuoy is working. kubetest seems to require a google cloud account, which requires giving credit card info to Google and other setup.  
export E2E_TEST_TOOL="SONOBUOY"
echo \$E2E_TEST_TOOL $E2E_TEST_TOOL

#-> use_case: what configuration (adjust EBS volumes accordingly).  
#	PERF - performance; requires io1 EBS volume
export USE_CASE="PERF"
echo \$USE_CASE $USE_CASE

#-> number of controllers, workers
export NUM_CONTROLLERS=1
export NUM_WORKERS=2
echo \$NUM_CONTROLLERS $NUM_CONTROLLERS
echo \$NUM_WORKERS $NUM_WORKERS

#-> OS to use
export OS="Ubuntu"
echo \$OS $OS

#-> at beginning, show config settings


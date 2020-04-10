#!/bin/bash

date
echo "StrictHostKeyChecking no" > ~/.ssh/config 

bash 00-config.sh
. set-var.sh

#Install with Kubeadm
if [ "$CLUSTER_INSTALL_METHOD" = "HARD_WAY" ]; then 
	STEP_SCRIPTS="02-certs.sh 03-generate-config-files.sh 04-encryption-keys.sh 05-bootstrapping-etcd.sh 06-bootstrapping-control-plane.sh 07-bootstrapping-worker-nodes.sh 08-kubectl-remote-access.sh 09-pod-network-routes.sh 10-dns-addon.sh "
elif [ "$CLUSTER_INSTALL_METHOD" = "KUBEADM" ]; then 
	STEP_SCRIPTS="02-use_kubeadm_install_cluster.sh "
else
	STEP_SCRIPTS=""
fi

if [ ! -z $STEP_SCRIPTS ]; then
	if [ "$WHICH_TESTS" = "SMOKE" ]; then 
		STEP_SCRIPTS+=" 11-smoke-tests.sh "
	elif [ "$WHICH_TESTS" = "SMOKE_AND_E2E" ]; then 
		STEP_SCRIPTS+=" 11-smoke-tests.sh 11-e2e-tests.sh"
	fi
fi

if [ -n "${CLEANUP}" -a "${CLEANUP}" -eq 1 ]; then
	STEP_SCRIPTS+=" 12-cleanup.sh"
fi

echo $STEP_SCRIPTS

echo "Starting deployment, configuration and validation of Kubernetes cluster."
echo "Deploying instances..."
bash -xv 01-provision-instances.sh > 01-provision-instances.sh.log 2>&1
. set-var.sh

for SCRIPT in $STEP_SCRIPTS
do
	echo "RUNNING $SCRIPT"
	bash -xv $SCRIPT > "${SCRIPT}.log" 2>&1
	RETVAL=$?
	ls -lh "${SCRIPT}.log"
	if [ $RETVAL -ne 0 ]; then
		echo "ERROR: $SCRIPT Failed. See ${SCRIPT} for details.  "
		if [ -n "${CLEANUP}" -a "${CLEANUP}" -eq 1 ]; then
			echo "Cleaning up resources and exiting now."
			bash -xv 12-cleanup.sh > 12-cleanup.sh.log 2>&1
		else
			echo "Exiting now. Resources will stay up for troubleshooting."
			break
		fi
		break
	fi
done
echo "Done."

rm -f ~/.ssh/config
date

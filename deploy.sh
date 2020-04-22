#!/usr/local/bin/bash

# Script used to deploy infrastructure for Kubernetes, and test and tear down as configured

date
# Turn prompting for ssh key off 
echo "StrictHostKeyChecking no" > ~/.ssh/config 

# Commands to run after each step script, if any
declare -A CMDS

CMDS["00-config.sh"]=""
CMDS["01-provision-instances.sh"]="grep 'running at' 01-provision-instances.sh.log | egrep '^Instance'"
CMDS["02-certs.sh"]=""
CMDS["02-use_kubeadm-initialize.sh"]=""
CMDS["02-use_kubeadm-kubelet-setup.sh"]=""
CMDS["02-use_kubeadm_install_cluster.sh"]="echo 'NODES and PODs:'; tail -30 02-use_kubeadm_install_cluster.sh.log | egrep -A 30 'kubectl get nodes; kubectl get pods'"
CMDS["03-generate-config-files.sh"]=""
CMDS["04-encryption-keys.sh"]=""
CMDS["05-bootstrapping-etcd.sh"]=""
CMDS["05-bootstrapping-etcd_on-controller.sh"]=""
CMDS["06-bootstrapping-control-plane.sh"]=""
CMDS["06-bootstrapping-control-plane_on-controller.sh"]=""
CMDS["06-bootstrapping-control-plane_on-controller0.sh"]=""
CMDS["07-bootstrapping-worker-nodes.sh"]=""
CMDS["07-bootstrapping-worker-nodes_on-worker.sh"]=""
CMDS["08-kubectl-remote-access.sh"]=""
CMDS["09-pod-network-routes.sh"]=""
CMDS["10-dns-addon.sh"]=""
CMDS["11-e2e-tests.sh"]=""
CMDS["11-e2e-tests_on-controller-kubetest.sh"]=""
CMDS["11-e2e-tests_on-controller.sh"]=""
CMDS["11-smoke-tests.sh"]=""
CMDS["11-smoke-tests_on-controller.sh"]=""
CMDS["12-cleanup.sh"]=""

# Get and run initial configuration
bash 00-config.sh
. set-var.sh

#Select install with Kubeadm or method specified in config
if [ "$CLUSTER_INSTALL_METHOD" = "HARD_WAY" ]; then 
	STEP_SCRIPTS="02-certs.sh 03-generate-config-files.sh 04-encryption-keys.sh 05-bootstrapping-etcd.sh 06-bootstrapping-control-plane.sh 07-bootstrapping-worker-nodes.sh 08-kubectl-remote-access.sh 09-pod-network-routes.sh 10-dns-addon.sh "
elif [ "$CLUSTER_INSTALL_METHOD" = "KUBEADM" ]; then 
	STEP_SCRIPTS="02-use_kubeadm_install_cluster.sh "
else
	STEP_SCRIPTS=""
fi

# Select which tests to run
if [ ! -z "$STEP_SCRIPTS" ]; then
	if [ "$WHICH_TESTS" = "SMOKE" ]; then 
		STEP_SCRIPTS+=" 11-smoke-tests.sh "
	elif [ "$WHICH_TESTS" = "SMOKE_AND_E2E" ]; then 
		STEP_SCRIPTS+=" 11-smoke-tests.sh 11-e2e-tests.sh"
	fi
fi

# Select whether to cleanup or not
if [ -n "${CLEANUP}" -a "${CLEANUP}" -eq 1 ]; then
	echo "Note: resources will be automatically deleted after deployment."
	STEP_SCRIPTS+=" 12-cleanup.sh"
else
	echo "Note: resources will be left up after deployment.  To cleanup, run teardown.sh."
fi

echo "Running the following scripts: 01-provision-instances.sh ${STEP_SCRIPTS}"

echo "Starting deployment, configuration and validation of Kubernetes cluster."
echo "Deploying instances with 01-provision-instances.sh..."
SCRIPT="01-provision-instances.sh"
bash -xv $SCRIPT > "${SCRIPT}.log" 2>&1
if [ ! -z "${CMDS[${SCRIPT}]}" ]; then
	eval "${CMDS[${SCRIPT}]}"
fi
ls -l 01-provision-instances.sh.log
. set-var.sh

# Run each script in steps needed
for SCRIPT in $STEP_SCRIPTS
do
    echo "================================================================"
	echo "RUNNING $SCRIPT"
	bash -xv $SCRIPT > "${SCRIPT}.log" 2>&1
	RETVAL=$?
	if [ ! -z "${CMDS[${SCRIPT}]}" ]; then
		eval "${CMDS[${SCRIPT}]}"  # show results from script
	fi
	ls -lh "${SCRIPT}.log"
	if [ $RETVAL -ne 0 ]; then  # If script failed, note it and recover appropriately
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

# Turn prompting for ssh key back on
rm -f ~/.ssh/config *.json *.kubeconfig *.yaml crt.txt
date

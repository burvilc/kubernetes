#!/bin/sh

NODE_TYPE=$1

if [ "${NODE_TYPE}" = "server" ]; then
	echo "Installing server ...."
	curl -sfL https://get.rke2.io | sudo sh -
	sudo systemctl enable rke2-server.service
	sudo systemctl start rke2-server.service
	sudo journalctl -u rke2-server 
elif [ "${NODE_TYPE}" = "worker" ]; then
	curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -	
	systemctl enable rke2-agent.service
	echo "Continue rest of install per https://docs.rke2.io/install/quickstart"
else
	echo "Need to enter server or worker as first argument."
	exit 1
fi






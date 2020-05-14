#!/bin/bash

date
echo "StrictHostKeyChecking no" > ~/.ssh/config 

. set-var.sh
echo "Shutting down instances..."
CMD="sudo init 0"
#CMD="df"

for IP in $INSTANCE_IPS; do 
	ssh -i "kubernetes.id_rsa" ubuntu@${IP} ${CMD} 
done


rm -f ~/.ssh/config
date

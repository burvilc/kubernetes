#!/bin/bash

date
echo "StrictHostKeyChecking no" > ~/.ssh/config 

. set-var.sh
. lib/functions; 
GetInstanceInfo $INSTANCE_INFO_FILE
. changed_vars.sh
rm -f changed_vars.sh
echo "Starting instances..."
CMD="uptime"
#CMD="df"

echo $INSTANCE_IDS

aws ec2 start-instances --instance-ids ${INSTANCE_IDS}


for ID in $INSTANCE_IDS; do 
	IP=""
	INSTANCE_UP=""
	echo "Starting Instance ID $ID"
	while [ -z "${IP}" ]; do
   		IP=$(aws ec2 describe-instances \
			--instance-ids $ID \
        	--output text --query 'Reservations[].Instances[].PublicIpAddress')
#barnabas:aws burvil$ aws ec2 describe-instances --instance-id i-0cf0e11eda7a3e5a2 --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]'
		NAME=$(aws ec2 describe-instances \
			--instance-ids $ID \
			--output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]')
		sleep 5
	done
	while [ -z "${INSTANCE_UP}" ]; do
		echo "Instance $NAME (id $ID) started, connecting at $IP"
		UPTIME=`ssh -i "kubernetes.id_rsa" ubuntu@${IP} ${CMD}`
		if [ $? -eq 0 ]; then
			INSTANCE_UP=1
			echo "Instance $ID (${IP}) running - ${UPTIME}"
			echo " --> Connect with:  ssh -i \"kubernetes.id_rsa\" ubuntu@${IP}"
			continue
		fi
		sleep 5
	done
done

rm -f ~/.ssh/config
date





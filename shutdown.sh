#!/bin/bash

date

. set-var.sh
. lib/functions; 
GetInstanceInfo $INSTANCE_INFO_FILE
. changed_vars.sh
rm -f changed_vars.sh

echo "Shutting down instances..."
CMD="sudo init 0"
#CMD="df"

aws ec2 stop-instances --instance-ids ${INSTANCE_IDS}

for ID in $INSTANCE_IDS; do 
		STATE_CODE=314
		while [ "${STATE_CODE}" -ne 80 ]; do 
        	STATE_CODE=$(aws ec2 describe-instances \
            	--instance-ids $ID \
            	--output text --query 'Reservations[].Instances[].State.Code')
        	sleep 5
		done
		echo "Instance $ID stopped."
done

date




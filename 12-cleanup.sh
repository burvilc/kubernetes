#!/bin/sh

RESULT=1

#Delete the controller and worker compute instances:

aws ec2 terminate-instances \
  --instance-ids \
    $(aws ec2 describe-instances \
      --filter "Name=tag:Name,Values=controller-*,worker-*" \
      --output text --query 'Reservations[].Instances[].InstanceId')
aws ec2 delete-key-pair --key-name kubernetes

#Networking
#Delete the external load balancer network resources:

INSTANCE_IDS=""
INSTANCE_IDS= $(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=controller-*,worker-*" \
		"Name=instance-state-name,Values=running" \
      --output text --query 'Reservations[].Instances[].InstanceId')

while [ -n "${RESULT}" -a  "${RESULT}" -ne 0 ]; do
	aws elbv2 delete-load-balancer --load-balancer-arn "${LOAD_BALANCER_ARN}"
	RESULT=$?
	sleep 20
done

while [ -n "${INSTANCE_IDS}" ]; do
	sleep 30
done

# Give enough time after load balancer deletion so it removes IP, etc. as well as EC2 instances to be fully terminated.
sleep 60

aws elbv2 delete-target-group --target-group-arn "${TARGET_GROUP_ARN}"
RESULT=1
while [ -n "${RESULT}" -a "${RESULT}" -ne 0 ]; do
	aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ID}"
	RESULT=$?
	sleep 20
done
sleep 30

ROUTE_TABLE_ASSOCIATION_ID="$(aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --output text --query 'RouteTables[].Associations[].RouteTableAssociationId')"
aws ec2 disassociate-route-table --association-id "${ROUTE_TABLE_ASSOCIATION_ID}"

aws ec2 delete-route-table --route-table-id "${ROUTE_TABLE_ID}"
aws ec2 detach-internet-gateway \
  --internet-gateway-id "${INTERNET_GATEWAY_ID}" \
  --vpc-id "${VPC_ID}"
aws ec2 delete-internet-gateway --internet-gateway-id "${INTERNET_GATEWAY_ID}"
aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"
aws ec2 delete-vpc --vpc-id "${VPC_ID}"

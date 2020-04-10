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

while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	aws elbv2 delete-load-balancer --load-balancer-arn "${LOAD_BALANCER_ARN}"
	RESULT=$?
	sleep 20
done

while [ -n "${INSTANCE_IDS}" ]; do
	sleep 10
done

# Give enough time after load balancer deletion so it removes IP, etc. as well as EC2 instances to be fully terminated.
sleep 30

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 20
	aws elbv2 delete-target-group --target-group-arn "${TARGET_GROUP_ARN}"
	RESULT=$?
done
sleep 10

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 20
	aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ID}"
	RESULT=$?
done
sleep 10

ROUTE_TABLE_ASSOCIATION_ID="$(aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --output text --query 'RouteTables[].Associations[].RouteTableAssociationId')"
RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 5 
	aws ec2 disassociate-route-table --association-id "${ROUTE_TABLE_ASSOCIATION_ID}"
	RESULT=$?
done

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 5 
	aws ec2 delete-route-table --route-table-id "${ROUTE_TABLE_ID}"
	RESULT=$?
done

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 5 
	aws ec2 detach-internet-gateway \
  		--internet-gateway-id "${INTERNET_GATEWAY_ID}" \
  		--vpc-id "${VPC_ID}"
	aws ec2 delete-internet-gateway --internet-gateway-id "${INTERNET_GATEWAY_ID}"
	RESULT=$?
done

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 5 
	aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"
	RESULT=$?
done

RESULT=1
while  [ -n "${RESULT}" ] && ( [ "${RESULT}" -ne 0 ] && [ "${RESULT}" -ne 254 ] ) ; do
	sleep 5 
	aws ec2 delete-vpc --vpc-id "${VPC_ID}"
	RESULT=$?
done


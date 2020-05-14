#/bin/bash

RETVAL=0
# Use io1 if doing E2E tests or if performance config chosen
if [ \( "${USE_CASE}" = "PERF" \) -o  \( "${WHICH_TESTS}" = "SMOKE_AND_E2E" \) ]; then
	MAPPING='{"DeviceName": "/dev/sda1", "Ebs": {"VolumeSize": 8, "VolumeType": "io1", "Iops" : 600 },  "NoDevice": "" }'
else
	MAPPING='{"DeviceName": "/dev/sda1", "Ebs": {"VolumeSize": 8 },  "NoDevice": "" }'
fi
echo $MAPPING

INSTANCE_IPS=""

#List of instance IDs for controllers, to be used later for target group
TARGET_GROUP_IPS=""

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=kubernetes-the-hard-way
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'

#########################
#Subnet
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.1.0/24 \
  --output text --query 'Subnet.SubnetId')
aws ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=kubernetes

#Internet Gateway
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 create-tags --resources ${INTERNET_GATEWAY_ID} --tags Key=Name,Value=kubernetes
aws ec2 attach-internet-gateway --internet-gateway-id ${INTERNET_GATEWAY_ID} --vpc-id ${VPC_ID}


####################
#Route Tables
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id ${VPC_ID} --output text --query 'RouteTable.RouteTableId')
aws ec2 create-tags --resources ${ROUTE_TABLE_ID} --tags Key=Name,Value=kubernetes
aws ec2 associate-route-table --route-table-id ${ROUTE_TABLE_ID} --subnet-id ${SUBNET_ID}
aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${INTERNET_GATEWAY_ID}

###################
#Security Groups (aka Firewall Rules)
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name kubernetes \
  --description "Kubernetes security group" \
  --vpc-id ${VPC_ID} \
  --output text --query 'GroupId')
aws ec2 create-tags --resources ${SECURITY_GROUP_ID} --tags Key=Name,Value=kubernetes
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.200.0.0/16
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${MYIP} 
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 6443 --cidr ${MYIP} 
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr ${MYIP} 
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol icmp --port -1 --cidr ${MYIP} 

#######################
# Compute Instances
#Instance Image
# Need to have aws command line configured to output to json; run aws configure to set this.
IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 \
  --filters \
  'Name=root-device-type,Values=ebs' \
  'Name=architecture,Values=x86_64' \
  'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*' \
  | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')

######################
#SSH Key Pair
aws ec2 create-key-pair --key-name kubernetes --output text --query 'KeyMaterial' > kubernetes.id_rsa
chmod 600 kubernetes.id_rsa

#######################
# Kubernetes Controllers
#Using instance types as defined in config file

#for i in 0 1 2; do
for i in $(seq 0 $MAX_CONTROLLER_I) ; do
  IP=10.0.1.1${i}
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type ${INSTANCE_TYPE} \
    --private-ip-address ${IP} \
    --user-data "name=controller-${i}" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings="${MAPPING}" \
    --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=controller-${i}"
  TARGET_GROUP_IPS+="Id=${IP} "
  INSTANCE_ID_FOR_CONTROLLER+=( $instance_id )
  echo "controller-${i} created "
done

####################
#Kubernetes Public Access - Create a Network Load Balancer
  LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name kubernetes \
    --subnets ${SUBNET_ID} \
    --scheme internet-facing \
    --type network \
    --output text --query 'LoadBalancers[].LoadBalancerArn')
  TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name kubernetes \
    --protocol TCP \
    --port 6443 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --output text --query 'TargetGroups[].TargetGroupArn')
  aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets ${TARGET_GROUP_IPS}
  aws elbv2 create-listener \
    --load-balancer-arn ${LOAD_BALANCER_ARN} \
    --protocol TCP \
    --port 443 \
    --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} \
    --output text --query 'Listeners[].ListenerArn'
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')

#########################
#Kubernetes Workers
#for i in 0 1 2; do
for i in $(seq 0 $MAX_WORKER_I); do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type ${INSTANCE_TYPE} \
    --private-ip-address 10.0.1.2${i} \
    --user-data "name=worker-${i}|pod-cidr=10.200.${i}.0/24" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings="${MAPPING}" \
    --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=worker-${i}"
  INSTANCE_ID_FOR_WORKER+=( $instance_id )
  echo "worker-${i} created"
done

for v in VPC_ID SUBNET_ID INTERNET_GATEWAY_ID ROUTE_TABLE_ID SECURITY_GROUP_ID LOAD_BALANCER_ARN TARGET_GROUP_ARN KUBERNETES_PUBLIC_ADDRESS IMAGE_ID
do
	echo "$v"
	export $v
	SETTING=`printenv | grep $v `
    echo "export $SETTING" >> set-var.sh
done
chmod 0755 set-var.sh

MAIN_CONTROLLER_INTERNAL_IP=""
echo "Waiting for instances to be up..."
for INSTANCE in $WORKER_NAMES $CONTROLLER_NAMES; do
  EXTERNAL_IP=""
  while [ -z "${EXTERNAL_IP}" ]; do
    if [[ "${INSTANCE}" =~ (controller)-([0-9]+) ]]; then
        i="${BASH_REMATCH[2]}"
        INSTANCE_ID=${INSTANCE_ID_FOR_CONTROLLER[${i}]}
    elif [[ "${INSTANCE}" =~ (worker)-([0-9]+) ]]; then
        i="${BASH_REMATCH[2]}"
        INSTANCE_ID=${INSTANCE_ID_FOR_WORKER[${i}]}
    fi
    FAILURE_STATE=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=terminated" \
	    --instance-id ${INSTANCE_ID} \
        --output text --query 'Reservations[].Instances[].StateTransitionReason')
	if [ ! -z "${FAILURE_STATE}" ]; then
		echo "Instance $INSTANCE (id ${INSTANCE_ID}) terminated with reason $FAILURE_STATE. Setting non-zero exit code."
		RETVAL=112
	fi
    EXTERNAL_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" \
        --output text --query 'Reservations[].Instances[].PublicIpAddress')
	if [ -z "${EXTERNAL_IP}" ]; then
		sleep 20
	else
    	if [ "${INSTANCE}" = "controller-0" ]; then
		  while [ -z "${MAIN_CONTROLLER_INTERNAL_IP}" ]; do
    		MAIN_CONTROLLER_INTERNAL_IP=$(aws ec2 describe-instances \
          		--filters "Name=tag:Name,Values=controller-0" "Name=instance-state-name,Values=running" \
          		--output text --query 'Reservations[].Instances[].PrivateIpAddress')
		  done
    	echo "export MAIN_CONTROLLER_INTERNAL_IP=$MAIN_CONTROLLER_INTERNAL_IP" >> set-var.sh
	    fi
		break # break out of loop if have external IP, whether controller-0 or not
	fi
  done
  echo "Instance ${INSTANCE} is running --> Connect to it with -- ssh -i \"kubernetes.id_rsa\" ubuntu@${EXTERNAL_IP}"
  INSTANCE_IPS+="  ${EXTERNAL_IP}" 
  echo "${INSTANCE_IPS}"
done

echo "export INSTANCE_IPS=\"${INSTANCE_IPS}\"" >> set-var.sh
exit $RETVAL

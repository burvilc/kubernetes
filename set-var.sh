export WHICH_TESTS=SMOKE
export CLUSTER_INSTALL_METHOD=KUBEADM
export CLEANUP=1
export NUM_CONTROLLERS=3
export NUM_WORKERS=3
export MAX_CONTROLLER_I=2
export CONTROLLER_NAMES=" controller-0 controller-1 controller-2"
export MAX_WORKER_I=2
export WORKER_NAMES=" worker-0 worker-1 worker-2"
export USE_CASE=STD
export E2E_TEST_TOOL=SONOBUOY
export OS=Ubuntu
export VPC_ID=vpc-0720727dd9a44ee92
export SUBNET_ID=subnet-0164497920a8722c2
export INTERNET_GATEWAY_ID=igw-01c9ad2a4c3e34a1c
export ROUTE_TABLE_ID=rtb-0e1f27d84b115302e
export SECURITY_GROUP_ID=sg-0afb41a71e2307256
export LOAD_BALANCER_ARN=arn:aws:elasticloadbalancing:us-west-2:201938144338:loadbalancer/net/kubernetes/d299c82c8d52dff1
export TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:us-west-2:201938144338:targetgroup/kubernetes/4a0113a177614346
export KUBERNETES_PUBLIC_ADDRESS=kubernetes-d299c82c8d52dff1.elb.us-west-2.amazonaws.com
export IMAGE_ID=ami-003634241a8fcdec0

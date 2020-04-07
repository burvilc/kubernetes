#!/bin/bash

sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt update -y
sudo apt install -y golang-go python3 python python-minimal python-pip gnupg unzip
# Needed for google cloud sdk, for gcloud for e2e testing
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo snap install --classic google-cloud-sdk
which gcloud


#curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#python get-pip.py --user
#pip install awscli --user
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version


export GOPATH="${HOME}/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
which go
find $HOME -name go

git clone https://github.com/kubernetes/test-infra.git

mv test-infra kubernetes
cd kubernetes 
ls -l kubetest
GO111MODULE=on go install ./kubetest

$HOME/go/bin/kubetest --help

kubetest --extract=v1.18.0

cd kubernetes

export KUBE_MASTER_IP_ADDR=`ip addr | egrep -A 3 ens5 | grep inet | grep -v inet6 | awk {'print $2'}  | sed 's/\/24//g'`
export KUBE_MASTER_IP="${KUBE_MASTER_IP_ADDR}:6443"
export KUBE_MASTER="controller-0"

kubetest --test --provider=aws --test_args="--ginkgo.focus=\[Conformance\]" | tee 12-e2e-test-results.log

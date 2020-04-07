#!/bin/bash

wget https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz

sudo tar -C /usr/local -xzf go1.14.1.linux-amd64.tar.gz
export GOPATH="${HOME}/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

go get -v -u k8s.io/test-infra/kubetest
which kubetest
sudo find / -name kubetest
exit

kubetest --extract=v1.18.0

cd kubernetes

export KUBE_MASTER_IP_ADDR=`ip addr | egrep -A 3 ens5 | grep inet | grep -v inet6 | awk {'print $2'}  | sed 's/\/24//g'`
export KUBE_MASTER_IP="${KUBE_MASTER_IP_ADDR}:6443"
export KUBE_MASTER="controller-0"

kubetest --verbose --test --provider=aws --test_args="--ginkgo.focus=\[Conformance\]" | tee 12-e2e-test-results.log

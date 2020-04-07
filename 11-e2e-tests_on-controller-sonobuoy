#!/bin/bash

#sudo add-apt-repository -y ppa:longsleep/golang-backports
#sudo apt update -y
#sudo apt install -y golang-go python3 python python-minimal python-pip gnupg unzip
#sudo apt install -y golang-go 

#export GOPATH="${HOME}/go"
#export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
wget https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.18.0/sonobuoy_0.18.0_linux_amd64.tar.gz
tar zxvf sonobuoy_0.18.0_linux_amd64.tar.gz
EXE=sonobuoy
file ${EXE}
sudo mv ${EXE} /usr/local/bin

#go get -v -u github.com/vmware-tanzu/${EXE}
 
which ${EXE} 
#sudo find $HOME -name ${EXE} 

${EXE} run --mode=certified-conformance --wait
RESULTS=$(${EXE} retrieve)

${EXE} e2e $RESULTS 

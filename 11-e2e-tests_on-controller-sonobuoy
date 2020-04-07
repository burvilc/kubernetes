#!/bin/bash

sudo tar -C /usr/local -xzvf $GO_TARBALL 
export GOPATH="${HOME}/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

EXE=sonobuoy

go get -v -u github.com/vmware-tanzu/${EXE}
 
which ${EXE} 
sudo find $HOME -name ${EXE} 

${EXE} run --mode=certified-conformance --wait
RESULTS=$(${EXE} retrieve)

${EXE} e2e $RESULTS 

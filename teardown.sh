#!/bin/bash

date
echo "StrictHostKeyChecking no" > ~/.ssh/config 

. set-var.sh
echo "Tearing down instances and supporting infrastructure for kubernetes ..."
bash -xv 12-cleanup.sh > 12-cleanup.sh.log 2>&1

rm -f ~/.ssh/config
date

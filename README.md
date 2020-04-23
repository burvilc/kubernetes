

barnabas:aws burvil$ ./deploy.sh
Tue Apr 21 18:32:59 PDT 2020
Note: resources will be left up after deployment.  To cleanup, run teardown.sh.
Running the following scripts: 01-provision-instances.sh 02-use_kubeadm_install_cluster.sh  11-smoke-tests.sh
Starting deployment, configuration and validation of Kubernetes cluster.
Deploying instances with 01-provision-instances.sh...
Instance worker-0 is running at external IP xx.xx.xx.xx 
Instance worker-1 is running at external IP xx.xx.xx.xx 
Instance controller-0 is running at external IP xx.xx.xx.xx 
-rw-r--r--  1 burvil  staff  28669 Apr 21 18:34 01-provision-instances.sh.log
================================================================
RUNNING 02-use_kubeadm_install_cluster.sh
NODES and PODs:
ssh -i kubernetes.id_rsa ubuntu@$MAIN_CONTROLLER_EXTERNAL_IP "source set-var.sh; kubectl get nodes; kubectl get pods -n kube-system"
+ ssh -i kubernetes.id_rsa ubuntu@xx.xx.xx.xx 'source set-var.sh; kubectl get nodes; kubectl get pods -n kube-system'
NAME           STATUS   ROLES    AGE    VERSION
ip-10-0-1-10   Ready    master   12m    v1.18.2
ip-10-0-1-20   Ready    <none>   3m4s   v1.18.2
ip-10-0-1-21   Ready    <none>   62s    v1.18.2
NAME                                   READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-dj2pt               1/1     Running   0          12m
coredns-66bff467f8-hkkz6               1/1     Running   0          12m
etcd-ip-10-0-1-10                      1/1     Running   0          12m
kube-apiserver-ip-10-0-1-10            1/1     Running   0          12m
kube-controller-manager-ip-10-0-1-10   1/1     Running   0          12m
kube-proxy-nrm9s                       1/1     Running   0          12m
kube-proxy-p56bl                       1/1     Running   0          3m4s
kube-proxy-pbdt4                       1/1     Running   0          62s
kube-scheduler-ip-10-0-1-10            1/1     Running   0          12m
weave-net-g4dpf                        2/2     Running   0          62s
weave-net-jct6d                        2/2     Running   0          7m50s
weave-net-lqwmx                        2/2     Running   1          3m4s

-rw-r--r--@ 1 burvil  staff   100K Apr 21 18:49 02-use_kubeadm_install_cluster.sh.log
================================================================
RUNNING 11-smoke-tests.sh
-rw-r--r--  1 burvil  staff    31K Apr 21 18:50 11-smoke-tests.sh.log
Done.
Tue Apr 21 18:50:06 PDT 2020

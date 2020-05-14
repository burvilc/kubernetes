DESCRIPTION
=======
This code is based initially on [Kubernetes the Hard Way](https://github.com/prabhatsharma/kubernetes-the-hard-way-aws).  However, as I soon found out that the process is essentially a learning tool for the [CKA exam](https://www.cncf.io/certification/cka/) and not an officially supported method of installation, I focused more of my efforts on installation with kubeadm.  Using kubeadm is documented at the official Kubernetes site at [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](here) and [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/](here). I used this information and other sites to write this code.  

Note that this code is by no means production ready.  My main intent was and is to provide a reasobly stable, secure and reliable method to deploy a Kubernetes cluster into AWS, and the code meets that requirement.  Suggestions for improvement are always welcome :)
    
CONFIGURATION/INSTALLATION
=======
1. Login to a system with bash 4.x or above.  
2. Get access to an AWS account. If needed, register for [AWS Free Tier](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc).
3. Install awscli (see this [AWS website](ihttps://aws.amazon.com/cli/) for details).
4. Configure AWS (see step 3) for a region, with the necessary credentials.
5. Perform a git clone of this repository to a locally available directory.
6. Edit 00-config.sh with appropriate values for your situation.  Note that running end-to-end tests will take 1-2 hours, and thus incur slightly higher costs, and that the t2.medium instance type required for Kubernetes to work (i.e. 2 CPUs/machine) will not be free under the free tier.

OPERATION
=======
An example run is as follows. Note that the output may be different, depending on configuration options chosen.

<pre>
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
</pre>

Once deployed, you should be able to ssh to your nodes, deploy pods, etc. as needed.  If you would like to delete the resources deployed and haven't set the CLEANUP flag in 00-config.sh to 1, run the teardown.sh script.

<pre>
barnabas:aws burvil$ ./teardown.sh
Wed Apr 22 22:47:14 PDT 2020
Tearing down instances and supporting infrastructure for kubernetes ...
Wed Apr 22 22:49:47 PDT 2020
</pre>

If you decide to leave your EC2 instances up and running, you can shut them down and bring them up as needed, to avoid unnecessary AWS charges.  Note that the public facing IP addresses will change each time this happens. 

The following are example runs of the startup and shutdown scripts to bring up or down the EC2 instances.  They take the information from the instance_info.csv file that was created by the provisioning script upon deployment. 

To shutdown:
<pre>
$ ./shutdown.sh
Thu May 14 12:40:37 PDT 2020
Shutting down instances...
{
    "StoppingInstances": [
        {
            "CurrentState": {
                "Code": 64,
                "Name": "stopping"
            },
            "InstanceId": "instance-1-id-here",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        },
        {
            "CurrentState": {
                "Code": 64,
                "Name": "stopping"
            },
            "InstanceId": "instance-2-id-here",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        },
        {
            "CurrentState": {
                "Code": 64,
                "Name": "stopping"
            },
            "InstanceId": "instance-3-id-here",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
Instance instance-3-id-here stopped.
Instance instance-2-id-here stopped.
Instance instance-1-id-here stopped.
</pre>

To startup:
<pre>
$ ./startup.sh
Thu May 14 12:51:15 PDT 2020
Starting instances...
instance-1-id-here instance-2-id-here instance-3-id-here
{
    "StartingInstances": [
        {
            "CurrentState": {
                "Code": 0,
                "Name": "pending"
            },
            "InstanceId": "instance-3-id-here",
            "PreviousState": {
                "Code": 80,
                "Name": "stopped"
            }
        },
        {
            "CurrentState": {
                "Code": 0,
                "Name": "pending"
            },
            "InstanceId": "instance-1-id-here",
            "PreviousState": {
                "Code": 80,
                "Name": "stopped"
            }
        },
        {
            "CurrentState": {
                "Code": 0,
                "Name": "pending"
            },
            "InstanceId": "instance-2-id-here",
            "PreviousState": {
                "Code": 80,
                "Name": "stopped"
            }
        }
    ]
}
Starting Instance ID instance-1-id-here
Instance instance-1-id-here started, connecting at ip-address-1-here
Warning: Permanently added 'ip-address-1-here' (ECDSA) to the list of known hosts.
Instance instance-1-id-here (ip-address-1-here) running -  19:51:45 up 0 min,  0 users,  load average: 0.45, 0.10, 0.03
Starting Instance ID instance-2-id-here
Instance instance-2-id-here started, connecting at ip-address-2-here
ssh: connect to host ip-address-2-here port 22: Connection refused
Instance instance-2-id-here started, connecting at ip-address-2-here
Warning: Permanently added 'ip-address-2-here' (ECDSA) to the list of known hosts.
Instance instance-2-id-here (ip-address-2-here) running -  19:52:05 up 0 min,  0 users,  load average: 0.59, 0.13, 0.04
Starting Instance ID instance-3-id-here
Instance instance-3-id-here started, connecting at ip-address-3-here
Warning: Permanently added 'ip-address-3-here' (ECDSA) to the list of known hosts.
Instance instance-3-id-here (ip-address-3-here) running -  19:52:14 up 0 min,  0 users,  load average: 0.83, 0.18, 0.06
Thu May 14 12:52:14 PDT 2020

</pre>


KNOWN BUGS/TODO
=======
1. Code is in need of refactoring, e.g. functions, modules, etc.
2. As noted earlier, installation via Kubernetes the Hard Way is not fully working; it currently hangs upon bootstrapping the control plane.  Given that it's not an officially supported method, further troubleshooting may not make sense. 
3. Support OS versions besides Ubuntu. Currently, the variable in the config file doesn't do anything. 
4. Specify specific version(s) of Kubernetes to install, e.g. to match/recreate a given environment.
5. The 12-cleanup.sh script sometimes doesn't completely delete resources properly.
6. Scripts to shutdown/startup cluster nodes, i.e. if CLEANUP is set to 0. 

TROUBLESHOOTING
=======
1. Check the log files for each iteration.  Sometimes errors in one script may be due to a previous script having issues.
2. Check that configuration values are set correctly in 00-config.sh.
3. Check the AWS console for errors, and there aren't duplicate resources provisioned.  Per the previous section, resources may not have cleaned up from the last run. 
4. If you cannot ssh to the servers, i.e. to the IP addresses in your deploy.sh output, ensure that your IP address is correct and is what AWS will see when you try to connect. 

CONTACT INFORMATION
=======
[https://www.linkedin.com/in/burvil/] (https://www.linkedin.com/in/burvil/)

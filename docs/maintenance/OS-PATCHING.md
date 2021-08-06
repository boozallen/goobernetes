# Operating system patches

## Patching the nodes

:information_source: This can be done during business hours, even in production, as it is completely non-disruptive to users.  Just make sure the cluster isn't hanging out at 100% utilization first and can spare having a node down for a while.

1. The first thing we're going to do is log in to the control plane and move everything off the target node as the `runner` user.

1. First, tell Kubernetes that this node shouldn't receive any new work.

    ```shell
    $ kubectl cordon runner-06.fqdn
    node/runner-06.fqdn cordoned
    ```

1. Next, evict all the pods from this node.  The two flags do some special stuff too.  `--ignore-daemonsets` ignores the pods running as a daemon to provide a service.  In our case, this is Prometheus metrics forwarding, Flannel networking, and the network proxy.

    ```shell
    $ kubectl drain runner-06.fqdn --ignore-daemonsets --delete-emptydir-data
    node/runner-06.fqdn already cordoned
    WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-flannel-ds-q86g5, kube-system/kube-proxy-9b9jb, lens-metrics/node-exporter-dpwx9
    evicting pod lens-metrics/kube-state-metrics-565db9f7c-zlqpf
    evicting pod actions-runner-system/actions-runner-controller-784954cf9f-8s5wv
    evicting pod default/ubuntu-runners-bgdgh-4q5t6
    evicting pod cert-manager/cert-manager-webhook-57d97ccc67-frfvj
    evicting pod default/ubuntu-runners-bgdgh-vk6r7
    pod/cert-manager-webhook-57d97ccc67-frfvj evicted
    pod/kube-state-metrics-565db9f7c-zlqpf evicted
    pod/actions-runner-controller-784954cf9f-8s5wv evicted
    pod/ubuntu-runners-bgdgh-vk6r7 evicted
    pod/ubuntu-runners-bgdgh-4q5t6 evicted
    node/runner-06.fqdn evicted
    ```

1. Give it a few moments, then verify nothing is on that node

    ```shell
    $ kubectl get nodes
    NAME                             STATUS                     ROLES                  AGE   VERSION
    runner-01.fqdn                   Ready                      control-plane,master   30d   v1.20.5
    runner-02.fqdn                   Ready                      <none>                 30d   v1.20.5
    runner-03.fqdn                   Ready                      <none>                 30d   v1.20.5
    runner-04.fqdn                   Ready                      <none>                 30d   v1.20.5
    runner-05.fqdn                   Ready                      <none>                 30d   v1.20.5
    runner-06.fqdn                   Ready,SchedulingDisabled   <none>                 20h   v1.20.5
    ```

1. Now connect to the target node and run OS updates.  I use the command below to avoid patching the Kubernetes version only, as I try to plan that upgrade using their documentation.  Then reboot the node and wait!

    ```shell
    sudo yum update --disablerepo=kubernetes -y
    sudo reboot
    ```

1. After a few minutes, check that the node appears as `Ready`.  From the control plane, run `kubectl get nodes` again.  If it's still `NotReady` in the STATUS field, give it another couple minutes, then investigate.  

1. Once it's back as `Ready` in the cluster, let things be scheduled on it again by running the following command from the control plane.

    ```shell
    $ kubectl uncordon runner-06.fqdn
    node/runner-06.fqdn uncordoned
    ```

1. Continue to the next node as needed until you're done. :)

## Patching the control plane

:information_source:  Do this during the maintenance window, as it's disruptive!  Same general process as above, but you can't cordon/drain the control plane.  I'd like to add a second control plane for HA in the future here.

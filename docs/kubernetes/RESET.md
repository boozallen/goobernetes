# Nuke it from orbit

:warning: Probably obvious, but this resets the whole cluster and you'll lose all your data.

1. (controller first, then nodes) Run the reset command.

    ```shell
    sudo kubeadm reset
    ```

2. (controller first, then nodes) Clean up and stop services, etc.

    ```shell
    sudo systemctl stop kubelet
    sudo systemctl stop docker
    sudo rm -rf /var/lib/cni/
    sudo rm -rf /var/lib/kubelet/*
    sudo rm -rf /etc/cni/
    sudo ifconfig cni0 down
    sudo ifconfig flannel.1 down
    sudo ifconfig docker0 down
    sudo ip link delete cni0
    sudo ip link delete flannel.1
    ```

3. (controller first, then nodes) Remove the configuration files.

    ```shell
    sudo rm -rf /home/runner/.kube
    ```

4. (controller) Initialize the cluster again.

    ```shell
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    ```

5. (controller first, then nodes) Recreate the kube config files.

    ```shell
    sudo mkdir -p /home/runner/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/runner/.kube/config
    sudo chown -R runner:runner /home/runner
    ```

6. (controller) Re-apply the network configuration.

    ```shell
    sudo su - runner
    kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    ```

7. (nodes) Re-join nodes to cluster.

    ```shell
    sudo kubeadm join ip-address-here:6443 --token weirdlongtoken \
    --discovery-token-ca-cert-hash sha256:shasumgoeshere
    ```

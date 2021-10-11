# Setting up a cluster with RHEL 7

## Ingredients

- 1 controller (I used the first numbered runner in each environment)
- X nodes to do the work

:information_source:  All nodes must have at least 2 CPUs!

## Automated setup directions for adding compute nodes

1. Create a new RHEL 7 VM
1. Join to IDM
1. Run yum updates and reboot
1. Run [this](../../ansible/actions-runner.yml) Ansible playbook and it'll do the setup steps for all nodes.

## Manual setup directions for all nodes

1. (all nodes) Create however many VMs you need, plus 1 for a controller.  Join them to IDM, install vmware tools, run updates, reboot, etc.  These should probably be reasonably beefy VMs.

1. (all nodes) Disable SELinux by editing `/etc/selinux/config`.  (TODO - Actually write a policy to prevent having to do this.)

    ```shell
    # This file controls the state of SELinux on the system.
    # SELINUX= can take one of these three values:
    #     enforcing - SELinux security policy is enforced.
    #     permissive - SELinux prints warnings instead of enforcing.
    #     disabled - No SELinux policy is loaded.
    SELINUX=permissive
    # SELINUXTYPE= can take one of three two values:
    #     targeted - Targeted processes are protected,
    #     minimum - Modification of targeted policy. Only selected processes are protected.
    #     mls - Multi Level Security protection.
    SELINUXTYPE=targeted
    ```

1. (all nodes) Enable Extras and Optional repos.

    ```shell
    sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
    sudo subscription-manager repos --enable=rhel-7-server-optional-rpms
    ```

1. (all nodes) Download the Docker CE repo.

    ```shell
    cd /etc/yum.repos.d/
    sudo wget https://download.docker.com/linux/centos/docker-ce.repo
    ```

1. (all nodes) Install Docker CE.

    ```shell
    sudo yum install docker-ce -y
    ```

1. (all nodes) Create a docker group so that users can run docker without superuser rights.

    ```shell
    sudo groupadd docker
    ```

1. (all nodes) Create a runner user and add it to the docker group.

    ```shell
    sudo useradd -mU runner
    sudo usermod -aG docker runner
    ```

1. (all nodes) Enable and start the Docker service.

    ```shell
    sudo systemctl enable docker.service --now
    ```

1. (all nodes) Create the repo file for Kubernetes at `/etc/yum.repos.d/kubernetes.repo` with the following contents:

    ```shell
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    ```

1. (all nodes) Install Kubernetes.

    ```shell
    sudo yum install kubelet kubeadm kubectl -y
    ```

1. (all nodes) Make a shiny network bridge by making a file at `/etc/sysctl.d/k8s.conf` with the following content:

    ```shell
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    ```

1. (all nodes) Reload.

    ```shell
    sudo sysctl --system
    ```

1. (all nodes) Turn off swap.

    ```shell
    sudo swapoff –a
    ```

1. (all nodes) Make that stick by editing `/etc/fstab` and commenting out the swap line.

1. (all nodes) Turn off firewalld.

    ```shell
    sudo systemctl disable firewalld
    sudo systemctl stop firewalld
    ```

1. (all nodes) Enable the kubelet service.

    ```shell
    sudo systemctl enable kubelet.service
    ```

## Setup directions for the controller

1. (controller) Run all the preflight checks and initialize.  :warning: **The address `10.244.0.0` is required for flannel!** :warning:

    ```shell
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    ```

1. (controller) Do the things to start the cluster.

    ```shell
    sudo mkdir -p /home/runner/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/runner/.kube/config
    sudo chown -R runner:runner /home/runner
    ```

1. (controller) Apply Flannel for networking.

    ```shell
    sudo su - runner
    kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    ```

1. (controller) Copy/paste the joining token for later.  It'll look something like what's in the next step.

1. (controller) Install helm.

    ```shell
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    sudo bash get_helm.sh
    ```

## Setup directions for the worker nodes

1. (worker nodes) Run the join command on each worker node.

    ```shell
    sudo kubeadm join IPADDRESSHERE:6443 --token WEIRDLONGTOKEN \
    --discovery-token-ca-cert-hash sha256:SHASUMGOESHERE
    ```

1. (controller) Verify the node has joined by running the command below:

    ```shell
    $ kubectl get nodes
    NAME                STATUS   ROLES                  AGE   VERSION
    dev-runner01.fqdn   Ready    control-plane,master   32m   v1.21.3
    dev-runner02.fqdn   Ready    <none>                 25s   v1.21.3
    ```

## Deploy the Actions controller on the controller

:information_source: All of these commands are run as the `runner` user.

1. Install and set up `cert-manager` (check the version).

    ```shell
    kubectl create namespace cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.4 --set installCRDs=true
    ```

1. Install and set up the Actions controller (check the version).

    ```shell
    kubectl create namespace actions-runner-system
    helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
    helm repo update
    helm install -n actions-runner-system actions-runner-controller actions-runner-controller/actions-runner-controller --version=0.13.2
    ```

1. Set up the controller to be the GitHub Enterprise Server in the appropriate environment.

    ```shell
    kubectl set env deploy actions-runner-controller -c manager GITHUB_ENTERPRISE_URL=https://HOSTNAME --namespace actions-runner-system
    ```

1. Set up the secret to control the runners.  This token _must_ have the `admin:enterprise` scope.  It does not require any other scope.

    ```shell
    kubectl create secret generic controller-manager -n actions-runner-system --from-literal=github_token=PATGOESHERE
    ```

1. Add a namespace for the runners to live in.

    ```shell
    kubectl create namespace runners
    kubectl create namespace test-runners
    ```

1. Add the secret to pull the container image from GitHub Packages.  Insert credentials as appropriate.  

    ```shell
    kubectl create secret docker-registry ghe -n runners --docker-server=https://docker.HOSTNAME --docker-username=ghe-username --docker-password=ghe-token --docker-email=youremail@domain.com
    kubectl create secret docker-registry ghe -n test-runners --docker-server=https://docker.HOSTNAME --docker-username=ghe-username --docker-password=ghe-token --docker-email=youremail@domain.com
    ```

1. Actually deploy the runners using any one of these [files](../deployments).  This could take some time based on if you need to pull the image.

    ```shell
    kubectl apply -f runnerdeployment.yml
    ```

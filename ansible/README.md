# What this folder is all about

This folder contains the playbooks used to provision and manage the RHEL 7 VMs that host the Kubernetes cluster.  Users don't have direct access to these machines, but nonetheless, they need to be configured and maintained.  That's what the files here are for. :tada:

## Getting up and running

First, you'll need to install Ansible and specify a user and SSH key to access the RHEL VMs.  Please set this in `$HOME/.ansible.cfg` or elsewhere if you'd like as specified in the [Ansible docs](https://docs.ansible.com/).  You will also need sudo privileges on the VMs.

The additional files needed and folder structure should be (roughly) as follows:

```shell
$HOME/.ansible.cfg
goobernetes/inventory.yml  # This is omitted in the public repository
```

Additionally, all the commands below assume you're running from the base directory of this repo. :)

The `inventory.yml` file uses the following roles:

- `kubeworkers` = The Kubernetes workers
- `kubecontrol` = The Kubernetes control plane(s)

Additionally, each node is also assigned an environment (`dev`, `int`, `prod`), to allow for using an intersection with it and the role of the VM.

## Provisioning a new VM as a Kubernetes worker

1. Request a new RHEL 7 VM with the same specs as the existing runner.
1. Do all the baseline configuration you need to and then reboot.
1. Next, run the `actions-runner.yml` playbook.  This installs all the software needed to join a Kubernetes cluster, then gets the join token from the control plane and joins this new worker to it.

    ```shell
    ansible-playbook -i inventory.yml ansible/actions-runner.yml
    ```

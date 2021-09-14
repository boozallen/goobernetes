# Goobernetes - the Kubernetes cluster of GitHub Actions runners

This is the repo that contains all the code and a walkthrough of building for an on-premises auto-scaling Kubernetes cluster of GitHub Actions Runners.

## But why though

Booz Allen Hamilton is a customer of GitHub Enterprise Server (and Cloud).  We frequently need to stay on-premises for regulatory reasons, but don't want to compromise on offering an excellent developer experience to our teammates.  With a wide variety of projects and people in our shared environment, we cannot spend time managing bespoke software dependencies on co-tenanted compute and troubleshooting interactions between project requirements.  It is simply not an option at our scale.

The end goal of this project is a minimally viable product of ephemeral Linux-based Kubernetes runners capable of Docker-in-Docker and easy customization.  It should be portable enough to host in your Kubernetes ecosystem of choice.  Source code, dependencies, and directions are listed below.

## Disclaimer

This works for us, in production, for the several thousand users in our installation.  I think it _should_ work with GitHub AE and Enterprise Cloud too, but I haven't tested that and YMMV.  If you try it, let us know how it's working!

## Documentation

There's a couple layers to this solution and each have their own docs.  If you're just going through this for the first time, we're going to assume you have the following things already set up:

- GitHub Enterprise Server (v3.0+) and that you have admin access to it.
- GitHub [Packages](https://docs.github.com/en/enterprise-server@3.1/admin/packages) and [Actions](https://docs.github.com/en/enterprise-server@3.1/admin/github-actions/enabling-github-actions-for-github-enterprise-server) are both already set up correctly and enabled.
- VMs provisioned however you need to to start building them into a Kubernetes cluster.  There's about a billion ways you can do this, so the setup directions are assuming minimal VMs on premises and using `kubectl` without anything fancy on top.

The foundation (for us) is on-prem hosting in vSphere.  It's in the same hosting cluster as GitHub Enterprise Server.  Each worker node is running Red Hat Enterprise Linux, mostly to be the same as all the other ancillary boxes that support GitHub.  The software and configuration of these nodes is controlled by Ansible playbooks.  Most of these have been omitted because they're very specific to our implementation - things such as baseline configuration, software installs, etc.  There is a single playbook, but not the inventory file, in the [ansible](ansible) directory to do the setup of a worker node.  If you prefer, the directions to do these steps manually are in the [cluster setup](docs/kubernetes/SETUP.md) page.  It should be possible to do this same task in many combinations of other virtualization platforms, operating systems, and configuration management tooling.

The next building block is the Kubernetes applications.  Here's some quick facts about how we set that up.

- [Flannel](https://github.com/flannel-io/flannel) controls the networking.
- [Cert-manager](https://cert-manager.io/) provides certificate generation and management.
- [Actions Runner Controller](https://github.com/actions-runner-controller/actions-runner-controller) is what actually connects to GitHub Enterprise Server and manages/scales the runners.
- [Helm](https://helm.sh/) is how all of the deployments are managed.

The next part of this solution is the Docker images used as runners.  These are what gets deployed as pods for GitHub to use.  There are currently five versions we've created, listed below:

- Ubuntu 20.04 (focal)
- Debian 10 (buster)
- Debian 11 (bullseye)
- CentOS 7 (centos7)
- CentOS 8 (centos8)

The Dockerfiles and all of the other software needed for each are in the [images](images) directory.  The extra scripts and such provide additional software, install and configure the runner agent to automatically join the enterprise worker pool, configure logging, etc.  In general, software that isn't commonly available in that distribution's default repositories is controlled by a shell script in the [software](images/software) directory.

The most visible part of the configuration for deploying these runners is in the [deployments](deployments) directory.  This directory only contains YAML files used to define the runner deployment.  Things you'll find here are how much resources are allotted to any given worker, how the controller scales that deployment, etc.

Lastly, the [workflows](github/workflows) directory provides the CI/CD pipeline for building, testing, and deploying the images.  Of course we're going to use GitHub to build GitHub! :tada:

## I just want the images to use

Neat!  Look at the packages to the right to download the latest image.  They're built monthly and on pull request against the `main` branch.

## How-to docs, next steps, and FAQs

- [Cluster setup](docs/kubernetes/SETUP.md)
- [Resetting the cluster](docs/kubernetes/RESET.md)
- [Docker images](docs/docker/BUILD.md)
- [Initial setup in GHES](docs/github/SETUP.md)
- [Next steps](docs/NEXT-STEPS.md)
- [Tips](docs/TIPS.md)

## Sources

You should read these, as they're all excellent and can provide more insight into the customization options and updates than are available in this repository.

- Kubernetes controller for self-hosted runners, on [GitHub](https://github.com/actions-runner-controller/actions-runner-controller), is the glue that makes this entire solution possible.
- Docker image for runners that can automatically join, which solved a good bit of getting the runner agent started automatically on each pod, [Write up](https://sanderknape.com/2020/03/self-hosted-github-actions-runner-kubernetes/) and [GitHub](https://github.com/SanderKnape/github-runner).
- GitHub's repository used to generate their runners' images ([GitHub](https://github.com/actions/virtual-environments)), where I got the idea of using shell scripts to layer discrete dependency management on top of a base image.  I can't provision full VMs as runners in my environment, as it appears the repository supports, but several of the [software](../images/software) scripts are copy/pasted directly out of that repo.

## Other Resources

- Don't know what the whole Kubernetes thing is about?  Here's some help:
  - The [Kubernetes Aquarium](https://medium.com/@AnneLoVerso/the-kubernetes-aquarium-6a3d1d7a2afd)
  - The Cloud Native Computing Foundation's book, [The Illustrated Children's Guide to Kubernetes](https://www.cncf.io/phippy/the-childrens-illustrated-guide-to-kubernetes/)
  - What helped me to understand this whole concept shift is to think that Kubernetes is to containers as KVM/vSphere/Hyper-V is to virtual machines.  It's probably not a perfect metaphor, but it helped. :smile:

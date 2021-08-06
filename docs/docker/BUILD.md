# Building the Docker images #

## The big idea ##

Each `*.Dockerfile` generates an image based on the operating system in the name and containing a minimum amount of additional software but for Docker and the software to install and auto-join runner agents.  Additional software installs are controlled by an adjacent `operating-system.sh` script.  That script mostly calls scripts in `images/software/` to actually install whatever software is wanted.

The goal is that `ubuntu-latest` (focal or 20.04) is as close to the `ubuntu-latest` labelled runner in GitHub.com as is requested on a feature-by-feature basis from our users.  I've been assuming that this is the default runner for most users.  The GitHub repository for GitHub's hosted runners is [here](https://github.com/actions/virtual-environments) and it's _awesome!_  However, it is also gigantic and pretty specific to Azure, so while I'll shamelessly pilfer the software management methodology, it's not going to work for us.

## Image building ##

Images are built and tested at pull requests against the `main` branch automatically.

- CentOS 7 [workflow](../../github/workflows/test-centos7.yml)
- Debian [workflow](../../github/workflows/test-debian.yml)
- Ubuntu [workflow](../../github/workflows/test-ubuntu.yml)

Images are built and pushed once those pull requests have been merged into the `main` branch by GitHub Actions.

- CentOS 7 [workflow](../../github/workflows/build-push-centos7.yml)
- Debian [workflow](../../github/workflows/build-push-debian.yml)
- Ubuntu [workflow](../../github/workflows/build-push-ubuntu.yml)

## Not entirely continuous deployment ##

You can do a lot with the deployment aspect of this project.  To keep it simple, I set the runner controller to always pull a fresh image and to ensure the pods are ephemeral.  This isn't _exactly_ continuous deployment, but I've found it works well enough.

## How to do this manually ##

If you'd like to build these manually on your own laptop, it's pretty straightforward.  Just meander into the `images` directory and run a Docker build like shown below.

```shell
cd images/
docker build -f image-name.Dockerfile -t tag-goes-here .
```

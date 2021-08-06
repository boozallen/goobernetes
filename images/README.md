# Docker stuff for the runners #

## Quick Facts ##

:question: Looking to add software to the runners?  If the package version that is currently in the default repositories for that OS is acceptable, add it to the appropriate Dockerfile.  If a newer version is needed or it isn't in the repositories, add a Bash script in the `software` folder and call that from the Dockerfile.

:information_source: In general, we're fine with adding software that's generally useful to people so long as it doesn't break existing things.  If you require a bespoke environment with specific dependency management, you should use your own compute.  You can find the directions for that [here](https://docs.github.com/en/enterprise-server@3.1/actions/hosting-your-own-runners/about-self-hosted-runners).

:warning: These are ephemeral pods!  Don't rely on the output being available between workflow steps, runs, etc.  GitHub Actions is also designed to be parallel by default, so try to use that to your advantage when you can.

## What this folder is all about ##

Here's a quick breakdown of the folder structure here:

- [docker](docker) - Contains the config files needed for the Docker daemon that runs inside each pod.  The pods are all capable of Docker-in-Docker, as quite a few Actions ship as Docker images.
- [patched](patched) - Has all the files around the Actions Runner software to run as a service.
- [software](software) - Bash scripts that install software on the pods at build time.
- [supervisor](supervisor) - The Debian-based runners use [supervisord](http://supervisord.org/) to launch/control Docker within the pod.

In addition to the folders above, here's a bit about the files in this folder.

- The Dockerfiles are ... exactly what you think they are really.
- `entrypoint.sh` - The entry point script launches the runner, connects to GitHub, and joins the enterprise pool.
- `logger.sh` - A handy dandy logger script!
- `modprobe` - Not really modprobe, but kinda needed to let Docker-in-Docker run more reliably.
- `startup.sh` - The startup script.  It's a bit ugly, but it works.  It relies on supervisord for the Debian-based runners, but if it fails (such as CentOS), it'll try `sudo $process` before failing for good.

# Next steps to improve your cluster

Here are some ideas for next steps to take to improve your cluster and take the solution a few steps beyond minimally viable.  These will provide some improvements if you aren't already using something with these features configured already.

- Log forwarding into your company's log collection tool
- Metrics and monitoring (again into your company's main tool for this sort of thing)
- More identity management / privileged access control than the two service accounts provided for Actions to use
- Docker image caching closer to the cluster.  The images of the pods themselves aren't the problem, as they're hosted on Packages and that should be pretty close to where the cluster is.  However, Packages does not support pull-through caching and many Actions are shipped as Docker images.  This means that if your users are pulling a lot of big images, it adds network usage and time to builds.  You can also get rate-limited upstream pretty fast, which can affect other systems on your network.  If you have an existing cache on your network, the easiest way I've found to add it is to the [daemon.json](../images/docker/daemon.json) file as an `insecure-registries` as detailed [here](https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file).

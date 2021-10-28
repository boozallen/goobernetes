# Creating and using a tool cache in the pods

:warning:  As you'd expect, this creates a really big pod image.

## Why

Running Actions at scale means that the `actions/setup-whatever` action continually re-downloads binaries from places that might rate limit unauthenticated requests.  To save bandwidth and headaches, it's easy to add a customizeable cache to each pod.

## How

This solution has a couple steps, but the templates are in this repo.  

1. Use [this workflow](../.github/workflows/make-tool-cache.yml) to create a zipped artifact of the tool cache.  The documentation on this and how it works is available [here](https://docs.github.com/en/enterprise-server@3.2/admin/github-actions/managing-access-to-actions-from-githubcom/setting-up-the-tool-cache-on-self-hosted-runners-without-internet-access).
2. Customize the workflow to have however many or few languages from [actions](https://github.com/actions) setup languages as your teams need.
3. Run the workflow and download the artifact.  Inflate it.
4. Create a second repository to hold the inflated artifacts.  More on this in the section below.
5. Commit and push all billions of files into that second repo.
6. Edit the Dockerfile and the build workflows as demonstrated below.  For the build workflow, we're going to add an extra [checkout](https://github.com/actions/checkout) step to pull down this repo into a specific directory for the Dockerfile to copy into the image and tell the runner agent where the cache is.

    ```YAML
    - name: Checkout this repo
      uses: actions/checkout@v2

    - name: Checkout the tool cache repo
      uses: actions/checkout@v2
      with:
        repository: ORG/CACHE-REPO
        path: images/cache
    ```

    ```Dockerfile
    COPY --chown=runner:docker cache /opt/hostedtoolcache
    ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
    ```

## More on the approach used here

While using GitHub to hold binary files isn't ideal, I'd found it to be the most performant option over copying the zipped file into the pod or trying to divine whether a team was using X or Y language and scripting something off that.  A potential better solution here would be to use a simple HTTP server or S3 bucket and inflate these files there, then using `wget` to grab them all during the image build.

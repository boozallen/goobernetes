FROM centos:8

# Set environment variables needed at build
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Copy in environment variables not needed at build
COPY .env /.env

# Install base software
RUN yum update -y \
    && yum install dnf-plugins-core -y \
    && yum config-manager --set-enabled powertools \
    && yum install -y \
    epel-release \
    git \
    krb5-libs \
    libicu \
    libyaml-devel \
    lttng-ust \
    openssl-libs \
    passwd \
    rpm-build \
    sudo \
    vim \
    wget \
    yum-utils \
    zlib \
    && yum clean all

# Runner user
RUN adduser -c "" --uid 1000 runner \
    && passwd -d runner \
    && groupadd docker \
    && usermod -aG docker runner \
    && echo "%docker  ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# Docker installation
RUN wget --no-verbose -O /tmp/install-docker.sh https://get.docker.com/ && \
    bash /tmp/install-docker.sh

# Install GitHub CLI
COPY software/gh-cli.sh gh-cli.sh
RUN bash gh-cli.sh && rm gh-cli.sh

# Install Hashicorp Packer
COPY software/packer.sh packer.sh
RUN bash packer.sh && rm packer.sh

# Install kubectl
COPY software/kubectl.sh kubectl.sh
RUN bash kubectl.sh && rm kubectl.sh
 
ARG TARGETPLATFORM=linux/amd64
ARG RUNNER_VERSION=2.283.3
ARG DEBUG=false

RUN test -n "$TARGETPLATFORM" || (echo "TARGETPLATFORM must be set" && false)

ENV RUNNER_ASSETS_DIR=/runnertmp

# Runner download supports amd64 as x64
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ]; then export ARCH=x64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh

RUN echo AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache > /runner.env \
    && mkdir /opt/hostedtoolcache \
    && chgrp runner /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache

COPY modprobe startup.sh /usr/local/bin/
COPY logger.sh /opt/bash-utils/logger.sh
COPY entrypoint.sh /usr/local/bin/
COPY docker/daemon.json /etc/docker/daemon.json

RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/entrypoint.sh /usr/local/bin/modprobe

RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && curl -L -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_${ARCH} \
    && chmod +x /usr/local/bin/dumb-init

VOLUME /var/lib/docker

COPY --chown=runner:docker patched $RUNNER_ASSETS_DIR/patched

# No group definition, as that makes it harder to run docker.
USER runner

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["startup.sh"]

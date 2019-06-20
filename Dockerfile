FROM ubuntu:latest
LABEL MAINTAINER="Petr Ruzicka <petr.ruzicka@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /home/docker

RUN addgroup --gid 1001 docker && \
    adduser --uid 1001 --ingroup docker --home /home/docker --shell /bin/sh --disabled-password --gecos "" docker

# https://github.com/boxboat/fixuid
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq libc-dev libvirt-clients libvirt-dev openssh-client pkg-config python3-cffi-backend python3-distutils python3-jinja2 python3-paramiko python3-pip python3-pyasn1 python3-setuptools python3-wheel python3-winrm python3-yaml qemu-kvm qemu-utils rsync sshpass unzip virtualbox-ext-pack virtualbox \
    \
    && pip3 install --no-cache-dir ansible \
    \
    && VAGRANT_LATEST_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant | jq -r -M '.current_version') \
    && curl -s https://releases.hashicorp.com/vagrant/${VAGRANT_LATEST_VERSION}/vagrant_${VAGRANT_LATEST_VERSION}_x86_64.deb --output /tmp/vagrant_x86_64.deb \
    && apt-get install --no-install-recommends -y /tmp/vagrant_x86_64.deb \
    && rm /tmp/vagrant_x86_64.deb \
    \
    && vagrant plugin install vagrant-libvirt \
    && chown -R docker:docker /home/docker \
    \
    && FIXUID_VERSION=$(curl --silent "https://api.github.com/repos/boxboat/fixuid/releases/latest" | sed -n 's/.*"tag_name": "v\([^"]*\)",/\1/p') \
    && curl -SsL https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - \
    && chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: docker\ngroup: docker\npaths:\n  - /home/docker" > /etc/fixuid/config.yml \
    \
    && apt-get purge -y curl jq libc-dev libvirt-dev pkg-config python3-distutils python3-pip python3-setuptools python3-wheel unzip \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

ADD startup_script.sh /

USER docker:docker

# The virtualbox driver device must be mounted from host
VOLUME /dev/vboxdrv

# The libvirt socket must be mounted from host
VOLUME /var/run/libvirt/libvirt-sock

WORKDIR /home/docker/vagrant

ENTRYPOINT ["/startup_script.sh"]

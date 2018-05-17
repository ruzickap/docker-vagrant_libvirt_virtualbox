FROM ubuntu:latest
LABEL MAINTAINER="Petr Ruzicka <petr.ruzicka@gmail.com>"

# VNC access to the virtual machine (https://www.packer.io/docs/builders/qemu.html#vnc_port_min)
EXPOSE 5999
# SSH port on the host machine which is forwarded to the SSH port on the guest machine (https://www.packer.io/docs/builders/qemu.html#ssh_host_port_min)
EXPOSE 2299

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl jq libc-dev libvirt-dev pkg-config qemu-kvm qemu-utils unzip virtualbox \
    && VAGRANT_LATEST_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant | jq -r -M '.current_version') \
    && curl https://releases.hashicorp.com/vagrant/${VAGRANT_LATEST_VERSION}/vagrant_${VAGRANT_LATEST_VERSION}_x86_64.deb --output /tmp/vagrant_x86_64.deb \
    && apt install -y /tmp/vagrant_x86_64.deb \
    && vagrant plugin install vagrant-libvirt vagrant-winrm \
    && apt purge -y curl jq libc-dev libvirt-dev pkg-config unzip \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

WORKDIR /var/tmp/box

ENTRYPOINT ["/usr/bin/vagrant"]



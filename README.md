[![Docker Hub; peru/vagrant_libvirt_virtualbox](https://img.shields.io/badge/dockerhub-peru%2Fvagrant_libvirt_virtualbox-green.svg)](https://registry.hub.docker.com/u/peru/vagrant_libvirt_virtualbox)[![](https://images.microbadger.com/badges/image/peru/vagrant_libvirt_virtualbox.svg)](https://microbadger.com/images/peru/vagrant_libvirt_virtualbox)[![Docker pulls](https://img.shields.io/docker/pulls/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)[![Docker Build](https://img.shields.io/docker/automated/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)

# Dockerfile with Vagrant (+ vagrant-libvirt and vagrant-winrm plugins), QEMU and VirtualBox.

This repository provides Dockerfile which can run Vagrant to start / manipulate VM images.

The docker image is primary created for testing Vagrant images built from Packer Templates located in this repository https://github.com/ruzickap/packer-templates.

## Installation steps

To use this Docker image you need to install VirtualBox and Docker to your OS (Fedora / Ubuntu). This may work on other operating systems too, but I didn't have a chance to test it.

### Ubuntu installation steps (Docker + Virtualbox)

```
sudo apt update
sudo apt install -y --no-install-recommends docker.io virtualbox
sudo gpasswd -a ${USER} docker

sudo reboot
```

### Fedora installation steps (Docker + Virtualbox)

```
sudo sed -i 's@^SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
sudo dnf upgrade -y
sudo dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y docker VirtualBox
sudo groupadd docker && sudo gpasswd -a ${USER} docker
sudo systemctl enable docker

sudo reboot
```

## Test box image created from Packer templates

Real example how to use the Docker image to test box image produced by Packer for libvirt/qemu.

```
mkdir ubuntu-18.04-server-amd64
cd ubuntu-18.04-server-amd64
docker run --rm -it -v $PWD:/var/tmp/box/ peru/vagrant_libvirt_virtualbox init peru/ubuntu-18.04-server-amd64
docker run -e VAGRANT_DEFAULT_PROVIDER=libvirt -p 5999:5999 --rm -it --privileged --cap-add=ALL -v /lib/modules:/lib/modules:ro -v $PWD:/var/tmp/box/ peru/vagrant_libvirt_virtualbox up
# or
docker run -e VAGRANT_DEFAULT_PROVIDER=virtualbox -p 5999:5999 --rm -it --privileged --cap-add=ALL -v /lib/modules:/lib/modules:ro -v $PWD:/var/tmp/box/ peru/vagrant_libvirt_virtualbox up
docker run --rm -it -v $PWD:/var/tmp/box/ peru/vagrant_libvirt_virtualbox ssh
```

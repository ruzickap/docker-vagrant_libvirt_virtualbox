# Dockerfile with Vagrant (+ vagrant-libvirt and vagrant-winrm plugins), QEMU and VirtualBox

[![Docker Hub; peru/vagrant_libvirt_virtualbox](https://img.shields.io/badge/dockerhub-peru%2Fvagrant_libvirt_virtualbox-green.svg)](https://registry.hub.docker.com/u/peru/vagrant_libvirt_virtualbox)[![Size](https://images.microbadger.com/badges/image/peru/vagrant_libvirt_virtualbox.svg)](https://microbadger.com/images/peru/vagrant_libvirt_virtualbox)[![Docker pulls](https://img.shields.io/docker/pulls/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)[![Docker Build](https://img.shields.io/docker/automated/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)

This repository provides Dockerfile which can run Vagrant to start / manipulate VM images.

The docker image is primary created for testing Vagrant images built from Packer Templates located in this repository [https://github.com/ruzickap/packer-templates](https://github.com/ruzickap/packer-templates).

## Installation steps

To use this Docker image you need to install VirtualBox and Docker to your OS (Fedora / Ubuntu). This may work on other operating systems too, but I didn't have a chance to test it.

### Ubuntu installation steps (Docker + Virtualbox)

```bash
sudo apt update
sudo apt install -y --no-install-recommends docker.io virtualbox
sudo gpasswd -a ${USER} docker

sudo reboot
```

### Fedora installation steps (Docker + Virtualbox)

```bash
sudo sed -i 's@^SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
sudo dnf upgrade -y
# Reboot if necessary (especialy if you upgrade the kernel or related packages)

sudo dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y akmod-VirtualBox curl docker git kernel-devel-$(uname -r) libvirt-daemon-kvm
sudo akmods

sudo bash -c 'echo "vboxdrv" > /etc/modules-load.d/vboxdrv.conf'
sudo usermod -a -G libvirt ${USER}
sudo groupadd docker && sudo gpasswd -a ${USER} docker
sudo systemctl enable docker

sudo reboot
```

## Test box image created from Packer templates

Real example how to use the Docker image to test box image produced by Packer for libvirt/qemu.

```bash
mkdir vagrant_box
cd vagrant_box

rsync -av --progress company-nb:/var/tmp/packer-templates-images/windows-server-2016-standard-x64-eval-libvirt.box .
rsync -av --progress company-nb:/var/tmp/packer-templates-images/my_ubuntu-18.04-server-amd64-libvirt.box .

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox set -x \
&& vagrant box add windows-server-2016-standard-x64-eval-libvirt.box --name=windows-server-2016-standard-x64-eval-libvirt --force \
&& vagrant init windows-server-2016-standard-x64-eval-libvirt \
&& vagrant up --provider libvirt \
&& vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:"OS Name" /C:"OS Version"' \
&& vagrant destroy --force \
&& vagrant box remove windows-server-2016-standard-x64-eval-libvirt \
&& virsh --connect=qemu:///system vol-delete --pool default --vol windows-server-2016-standard-x64-eval-libvirt_vagrant_box_image_0.img \
&& rm -rf {Vagrantfile,.vagrant}

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox set -x \
&& vagrant box add my_ubuntu-18.04-server-amd64-libvirt.box --name=my_ubuntu-18.04-server-amd64-libvirt --force \
&& vagrant init my_ubuntu-18.04-server-amd64-libvirt \
&& vagrant up --provider libvirt \
&& vagrant ssh --command 'grep PRETTY_NAME /etc/os-release; id' \
&& vagrant destroy --force \
&& vagrant box remove my_ubuntu-18.04-server-amd64-libvirt \
&& virsh --connect=qemu:///system vol-delete --pool default --vol my_ubuntu-18.04-server-amd64-libvirt_vagrant_box_image_0.img \
&& rm -rf {Vagrantfile,.vagrant}

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox set -x \
&& vagrant box add my_ubuntu-18.04-server-amd64-virtualbox.box --name=my_ubuntu-18.04-server-amd64-virtualbox --force \
&& vagrant init my_ubuntu-18.04-server-amd64-virtualbox \
&& sed -i '/config.vm.box =/a \ \ config.vm.provider "virtualbox" do |v|\n \ \ \ v.gui = false\n\ \ end' Vagrantfile \
&& vagrant up --provider virtualbox \
&& vagrant ssh --command 'grep PRETTY_NAME /etc/os-release; id' \
&& vagrant destroy --force \
&& vagrant box remove my_ubuntu-18.04-server-amd64-virtualbox \
&& rm -rf {Vagrantfile,.vagrant}

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
docker-vagrant_libvirt_virtualbox set -x \
&& vagrant box add my_windows-10-enterprise-x64-eval-virtualbox.box --name=my_windows-10-enterprise-x64-eval-virtualbox --force \
&& vagrant init my_windows-10-enterprise-x64-eval-virtualbox \
&& sed -i '/config.vm.box =/a \ \ config.vm.provider "virtualbox" do |v|\n \ \ \ v.gui = false\n\ \ end' Vagrantfile \
&& vagrant up --provider virtualbox \
&& vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:"OS Name" /C:"OS Version"' \
&& vagrant destroy --force \
&& vagrant box remove my_windows-10-enterprise-x64-eval-virtualbox \
&& rm -rf {Vagrantfile,.vagrant}
```

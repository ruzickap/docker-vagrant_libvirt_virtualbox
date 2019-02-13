# Dockerfile with Vagrant (+ vagrant-libvirt and vagrant-winrm plugins), QEMU and VirtualBox

[![Docker Hub; peru/vagrant_libvirt_virtualbox](https://img.shields.io/badge/dockerhub-peru%2Fvagrant_libvirt_virtualbox-green.svg)](https://registry.hub.docker.com/u/peru/vagrant_libvirt_virtualbox)[![Size](https://images.microbadger.com/badges/image/peru/vagrant_libvirt_virtualbox.svg)](https://microbadger.com/images/peru/vagrant_libvirt_virtualbox)[![Docker pulls](https://img.shields.io/docker/pulls/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)[![Docker Build](https://img.shields.io/docker/automated/peru/vagrant_libvirt_virtualbox.svg)](https://hub.docker.com/r/peru/vagrant_libvirt_virtualbox/)

This repository provides Dockerfile which can run Vagrant to start / manipulate VM images.

The docker image is primary created for testing Vagrant images built from Packer Templates located in this repository [https://github.com/ruzickap/packer-templates](https://github.com/ruzickap/packer-templates).

## Installation steps

To use this Docker image you need to install VirtualBox and Docker to your OS (Fedora / Ubuntu). This may work on other operating systems too, but I didn't have a chance to test it.

### Ubuntu installation steps (Docker + Virtualbox)

```bash
sudo apt update
sudo apt install -y --no-install-recommends docker.io jq libvirt-bin virtualbox wget
sudo gpasswd -a ${USER} docker
# This is mandatory for Ubuntu otherwise docker container will not have access to /dev/kvm - this is default in Fedora (https://bugzilla.redhat.com/show_bug.cgi?id=993491)
sudo bash -c "echo 'KERNEL==\"kvm\", GROUP=\"kvm\", MODE=\"0666\"' > /etc/udev/rules.d/60-qemu-system-common.rules"
sudo sed -i 's/^unix_sock_/#&/' /etc/libvirt/libvirtd.conf
sudo reboot
```

### Fedora installation steps (Docker + Virtualbox)

```bash
sudo sed -i 's@^SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
sudo dnf upgrade -y
# Reboot if necessary (especially if you upgrade the kernel or related packages)

sudo dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y akmod-VirtualBox curl docker git jq kernel-devel-$(uname -r) libvirt-daemon-kvm wget
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
BOXES="windows-10-enterprise-x64-eval ubuntu-18.04-server-amd64"

mkdir vagrant_box
cd vagrant_box

for BOX in $BOXES; do
  CURRENT_VERSION=$(curl -s https://app.vagrantup.com/api/v1/box/peru/$BOX | jq -r ".current_version.version")
  wget -c https://app.vagrantup.com/peru/boxes/$BOX/versions/$CURRENT_VERSION/providers/libvirt.box -O ${BOX}-libvirt.box
  wget -c https://app.vagrantup.com/peru/boxes/$BOX/versions/$CURRENT_VERSION/providers/virtualbox.box -O ${BOX}-virtualbox.box
done

docker pull peru/vagrant_libvirt_virtualbox

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox "set -x \
&& vagrant box add windows-10-enterprise-x64-eval-libvirt.box --name=windows-10-enterprise-x64-eval-libvirt --force \
&& vagrant init windows-10-enterprise-x64-eval-libvirt \
&& vagrant up --provider libvirt \
&& vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:\"OS Name\" /C:\"OS Version\"' \
&& vagrant destroy --force \
&& vagrant box remove windows-10-enterprise-x64-eval-libvirt \
&& virsh --connect=qemu:///system vol-delete --pool default --vol windows-10-enterprise-x64-eval-libvirt_vagrant_box_image_0.img \
&& rm -rvf Vagrantfile .vagrant"

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox "set -x \
&& vagrant box add windows-10-enterprise-x64-eval-virtualbox.box --name=windows-10-enterprise-x64-eval-virtualbox --force \
&& vagrant init windows-10-enterprise-x64-eval-virtualbox \
&& sed -i '/config.vm.box =/a \ \ config.vm.provider \"virtualbox\" do |v|\n \ \ \ v.gui = false\n\ \ end' Vagrantfile \
&& vagrant up --provider virtualbox \
&& vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:\"OS Name\" /C:\"OS Version\"' \
&& vagrant destroy --force \
&& vagrant box remove windows-10-enterprise-x64-eval-virtualbox \
&& rm -rvf Vagrantfile .vagrant"

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox "set -x \
&& vagrant box add ubuntu-18.04-server-amd64-libvirt.box --name=ubuntu-18.04-server-amd64-libvirt --force \
&& vagrant init ubuntu-18.04-server-amd64-libvirt \
&& vagrant up --provider libvirt \
&& vagrant ssh --command 'grep PRETTY_NAME /etc/os-release; id' \
&& vagrant destroy --force \
&& vagrant box remove ubuntu-18.04-server-amd64-libvirt \
&& virsh --connect=qemu:///system vol-delete --pool default --vol ubuntu-18.04-server-amd64-libvirt_vagrant_box_image_0.img \
&& rm -rf Vagrantfile .vagrant"

docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
-e HOME=/home/docker \
-v /dev/vboxdrv:/dev/vboxdrv \
-v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
-v $PWD:/home/docker/vagrant \
peru/vagrant_libvirt_virtualbox "set -x \
&& vagrant box add ubuntu-18.04-server-amd64-virtualbox.box --name=ubuntu-18.04-server-amd64-virtualbox --force \
&& vagrant init ubuntu-18.04-server-amd64-virtualbox \
&& sed -i '/config.vm.box =/a \ \ config.vm.provider \"virtualbox\" do |v|\n \ \ \ v.gui = false\n\ \ end' Vagrantfile \
&& vagrant up --provider virtualbox \
&& vagrant ssh --command 'grep PRETTY_NAME /etc/os-release; id' \
&& vagrant destroy --force \
&& vagrant box remove ubuntu-18.04-server-amd64-virtualbox \
&& ls -la && pwd \
&& rm -rvf Vagrantfile .vagrant"
```

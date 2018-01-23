# Packer.io-based image creation

The images for the Vagrant setup are created via [packer](https://www.packer.io). Follow these instructions to create your own images.

## Contents

This directory holds packer configuration files for the following combinations of storage software, operating systems and virtual machine platforms:

|Storage Software|Operating System|VM Platform|Packer file|
|---|---|---|---|
|Red Hat Ceph Storage 3.0|Red Hat Enterprise Linux 7|VirtualBox|packer-virtualbox-rhcs-3.0-rhel-7.json|
|Red Hat Ceph Storage 3.0|Red Hat Enterprise Linux 7|libvirtd|packer-libvirt-rhcs-3.0-rhel-7.json|


## Requirements
* macOS with [Virtualbox](https://www.virtualbox.org/wiki/Downloads) (starting 5.1.30) **or**
* RHEL 7.4/Fedora 27 with KVM/libvirt
* [Vagrant](https://www.vagrantup.com) (starting 1.9.1)
* [Packer](https://www.packer.io) (starting 1.1.3)
* [Ansible](https://ansible.com) (starting 2.4.2.0)
* git
* an ISO for one of the supported OS, e.g. RHEL 7.4 ISO
* **Red Hat VPN access**

## Get started
* Create an output directory for the resulting .box file (e.g. /tmp/rhcs-rhel-7-virtualbox)
* Download OS disc ISO (e.g. RHEL 7.4 Binary DVD)
  * put it somewhere (e.g. /tmp/rhel-server-7.4-x86_64-dvd.iso)
* Clone this repository
  * `git clone -b packer https://github.com/red-hat-storage/RHCS-vagrant.git`
* Goto the folder in which you cloned this repo
  * `cd RHCS-vagrant/packer`
* If yo have already cloned this repo earlier, make sure you are up to update
  * `git pull`
* Tell packer where to find your ISO, e.g.
  * `export ISO_FILE_PATH=file:///tmp/rhel-server-7.4-x86_64-dvd.iso`
* Tell packer where to store the resulting OVA
  * `export OUTPUT_DIRECTORY=/tmp/rhcs-rhel-7-virtualbox`
* make sure you are logged on to the RHT VPN
* run packer, e.g.
  * `packer build packer-virtualbox-rhcs-3.0-rhel-7.json`

## Author
[Daniel Messer](mailto:dmesser@redhat.com)

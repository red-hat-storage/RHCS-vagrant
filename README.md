# RHCS 3.0 in Vagrant

A Vagrant setup for Red Hat Ceph Storage version 3.0.
This will setup as many RHCS nodes as you want with a number of OSDs that you can define! You can choose between rpm-based install or Ceph running in containers.
Optionally you can choose to deploy the monitoring UI [ceph-metrics](https://github.com/ceph/cephmetrics).

## Requirements
* macOS with [Virtualbox](https://www.virtualbox.org/wiki/Downloads) (starting 5.1.30) **or**
* RHEL 7.4/Fedora 27 with KVM/libvirt
* [Ansible](https://ansible.com) (starting 2.4.0.0)
* [Vagrant](https://www.vagrantup.com) (starting 1.9.1)
* git
* `python-netaddr`

## Before you start - installation instructions for Vagrant / Ansible and dependencies

#### On RHEL 7.4 / CentOS 7

* make sure you are logged in as a user with `sudo` privileges
* on RHEL 7 make sure your system has the following repositories enabled (`yum repolist`)
  * rhel-7-server-rpms
  * rhel-7-server-extras-rpms
* install the requirements
  * `sudo yum groupinstall "Virtualization Host"`
  * `sudo yum install ansible git gcc libvirt-devel`
  * `sudo yum install python-netaddr`
  * `sudo yum install https://releases.hashicorp.com/vagrant/2.0.1/vagrant_2.0.1_x86_64.rpm`
* start `libvirtd`
  * `sudo systemctl enable libvirtd`
  * `sudo systemctl start libvirtd`
* enable libvirt access for your current user
  * `sudo gpasswd -a $USER libvirt`
* as your normal user, install the libvirt plugin for vagrant
  * `vagrant plugin install vagrant-libvirt`

#### On Fedora 27

* make sure you are logged in as a user with `sudo` privileges
* make sure your system has the following repositories enabled (`dnf repolist`)
  * fedora
  * fedora-updates
* install the requirements
  * `sudo dnf install ansible git gcc libvirt-devel libvirt qemu-kvm`
  * `sudo dnf install vagrant vagrant-libvirt`
  * `sudo dnf install python-netaddr`
* start `libvirtd`
  * `sudo systemctl enable libvirtd`
  * `sudo systemctl start libvirtd`
* enable libvirt access for your current user
  * `sudo gpasswd -a $USER libvirt`
* as your normal user, install the libvirt plugin for vagrant
  * `vagrant plugin install vagrant-libvirt`

#### On macOS High Sierra

* install the requirements
  * install [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
  * install [Vagrant](https://www.vagrantup.com)
  * install [homebrew](https://brew.sh/)
  * install git
    * `brew install git`
  * install ansible
    * `brew install ansible`
  * install python pip
    * `sudo easy_install pip`
  * install python-netaddr
    * `pip install netaddr`

## Get started
* You **must** be in the Red Hat VPN
* Clone this repository
  * `git clone https://github.com/red-hat-storage/RHCS-vagrant.git`
* Goto the folder in which you cloned this repo
  * `cd RHCS-vagrant`
* if you are a returning user run `git pull` to ensure you have the latest updates
* if you are on RHEL/Fedora and you don't want your libvirt storage domain `default` to be used, override the storage domain like this
  * `export LIBVIRT_STORAGE_POOL=images`
* Run `vagrant up`
  * Decide between the installation type (rpm-based vs. containerized)
	* Decide whether you want to use filestore or bluestore (the latter is preview)
  * Decide how many OSD nodes and how many devices you need
	* rpm-based install: decide how many MON, RGW, MDS, etc. nodes you want
	* containerized install: decide whether or not and how many additional ceph services (RGW, MDS, etc.) you want to co-locate to the OSD nodes
  * Decide if you want a separate client node
  * Decide if you want vagrant to initialize the cluster (using `ceph-ansible`) for you
  * If you opted to initialize the cluster, decide whether you want to deploy `ceph-metrics` (**only available for rpm-based filestore-backed clusters**)
  * Wait a while
* If you like to start over: `vagrant destroy -f`

## Usage
* *Always make sure you are in the git repo - vagrant only works in there!*
* After `vagrant up` you can connect to each VM with `vagrant ssh` and the name of the VM you want to connect to
  * the password for the `vagrant` user is 'vagrant'
* Each VM is called according to the Ceph node type (e.g. `OSDx` or `MONx` where x starts with 1
  * There is an additional VM called `METRICS` which hosts the Ceph Metrics Monitoring Stack if you selected to deploy it (URL is displayed at the end of `vagrant up`)
	* If you selected an rpm-based install log on to one of the MON nodes to use ceph client utilities and administer the cluster
* There are also other vagrant commands you should check out!
  * if you want to throw away everything: `vagrant destroy -f`
  * if you want to freeze the VMs and continue later: `vagrant suspend`
  * Try `vagrant -h` to find out about them
  * if you run `vagrant up` again you without running `vagrant destroy` before you will overwrite your configuration and vagrant may loose track of some VMs (it's safe to remove them manually)
* modify the `VMMEM` and `VMCPU` variables in the Vagrant file to change RHCS VM resources, adjust `VMDISK` to change OSD device sizes

## What happens under the covers
* After starting the RHCS VMs on all nodes:
  * the hosts file is pre-populated
  * all ceph packages and docker images are pre-installed (allows you to continue offline)
  * the RHEL images are subscribed to YUM repositories on the RHT VPN
  * a `ceph-ansible` setup is prepared in `/usr/share/ceph-ansible` and the inventory file is set up in `/etc/ansible/hosts`
* If you decided to have vagrant initialize the cluster and you chose an rpm-based install:
  * `ceph-ansible`'s `site.yml` playbook was executed
  * the selected ceph roles were installed on the respective VMs (named after the role)
  * cluster is up and in HEALTHY state
* If you decided to have vagrant initialize the cluster and you chose an containerized install:
  * the selected amount of OSD VMs were created
	* docker service is enabled and started (using overlay2 on a separate logical volume)
  * `ceph-ansible`'s `site-docker.yml` playbook was executed
  * the selected ceph roles were installed in containers on the OSD nodes (one per node)
    * as of today containerized iSCSI is not yet supported
	* cluster is up and in HEALTHY state
* If you decided to deploy `ceph-metrics` (only available when initializing the cluster and only for rpm-based install with `filestore` as the OSD backend)
  * an additional VM called METRICS will run `ceph-metrics` dashboard components
  * at the end of the metrics deployment you will see the URL to reach the dashboard displayed
* If you opted out of cluster initialization a working `ceph-ansible` was left in place for your convenience

## Clean up / Refresh images

If you like to clean up disk space or there are updates to the images do the following:

* run `rm ~/.vagrant.d/boxes/*-rhcs-*.box` and `rm ~/.vagrant.d/boxes/*-metrics-*.box` to delete older Vagrant images
* on VirtualBox - remove the VM instances named `packer-...` (these are base images for the clones)
* on libvirt
  * run `virsh vol-list default` to list all images in your `default` storage pool (adjust the name if you are using a different one)
  * run `virsh vol-delete packer-... default` to delete the images starting with `packer-...` (replace with full name) from the default pool

Next time you do `vagrant up` it will automatically pull new images.

## Known issues
* `vagrant up` overrides your state - if there are still VMs running and you do `vagrant up` it will override the `vagrant_env.conf` and vagrant will loose track of your existing VMs
  * try to remember to run `vagrant destroy -f` before you do another `vagrant up`
  * delete left-over VMs manually in case you forgot
* containerized installation of RHCS fails at stage `pull {{ ceph_docker_image }} image` with the error message:
  * Get https://registry.access.redhat.com/v2/rhceph/rhceph-3-rhel7/manifests/latest: read tcp ...: connection reset by peer
  * the Red Hat Registry is temporarily unavailable - please try again later

### Creating your own vagrant box

If you - for whatever reason - do not want to use my prebuilt box, you can create your own box very easy!  

**BEWARE** this is for advanced users only!

* Get [packer](https://www.packer.io/)
* run `git checkout -b packer` to switch the "packer" branch of this repository, follow the README in packer directory

## Author
[Daniel Messer](mailto:dmesser@redhat.com) - [dmesser@redhat.com](mailto:dmesser@redhat.com) -
Technical Marketing Manager @ Red Hat

## Original Authors
[Christopher Blum](https://github.com/zeichenanonym)
Stephan Hohn

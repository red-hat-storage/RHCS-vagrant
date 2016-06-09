# RHSC / USM / RHSCON in Vagrant (Based on RHSC 2.0.0)

A Vagrant setup for Red Hat Ceph Storage based on RHEL 7. This will setup as many RHCS nodes as you want with a number of OSDs that you can define! As added Bonus you get a VM for USM, which will allow you to easily configure the Ceph environment.


## Requirements
* [Virtualbox](https://www.virtualbox.org/wiki/Downloads) or KVM (We recommend to use libvirt + qemu-kvm)
* [Vagrant](https://www.vagrantup.com/) (latest version) and the following vagrant plugins
* Git

### KVM / Libvirt setup for vagrant


	# -------------------------------------------------------
	# RHEL 7 instructions (see below for Fedora instructions)
	# -------------------------------------------------------

	# Install gcc, libvirt, libvirt-devel, qemu-kvm and tigervnc
	sudo yum -y install gcc libvirt libvirt-devel qemu-kvm tigervnc

	# Install Vagrant RPM from http://www.vagrantup.com/downloads.html
	sudo rpm -i https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.rpm

	# Install vagrant-libvirt
	vagrant plugin install vagrant-libvirt

	# Start libvirtd
	sudo systemctl enable libvirtd.service
	sudo systemctl start libvirtd.service

	# Now follow RHEL 7 and Fedora instructions (see below)

	# -------------------
	# Fedora instructions
	# -------------------

	# Install nfs-utils, tigervnc and vagrant-libvirt
	sudo dnf -y install nfs-utils tigervnc vagrant-libvirt

	# Now follow RHEL 7 and Fedora instructions (see below)

	# ------------------------------
	# RHEL 7 and Fedora instructions
	# ------------------------------

	# Ensure your firewall allows your Vagrant VMs to access your host (e.g. for
	# NFS).  Note that out of the box with vagrant-libvirt your VMs will come up
	# on interface virbr1, not virbr0

	# Example using firewalld
	sudo firewall-cmd --permanent --add-interface=virbr1 --zone=trusted
	sudo firewall-cmd --reload

	# Add yourself to the libvirt group to avoid incessant password prompts
	sudo gpasswd -a $USER libvirt
	newgrp libvirt
Source: <http://demobuilder.gps.hst.ams2.redhat.com/> From Jim Minter's Demo Builder Page


## Get started
* Clone this repository
 * `git clone git@github.com:red-hat-storage/RHCS-vagrant.git`
* switch into this branch
 *  `git checkout RHSC`
* Run `vagrant up --no-provision`
	* If you have multiple virtualisation programs installed, you might need to explicitely select one like this: `vagrant up --provider=libvirt --no-provision`    
* Decide how many storage nodes and disks these nodes should have
* Wait a while for the deployment to finish
* First provision the USM node:
 * `vagrant provision RHS-C`
* Then provision your storage nodes:
 * `vagrant provision RHCS1 RHCS2 RHCS3 [...]` (Depending on how many storage nodes you have started)
* Connect to <http://localhost:10443>
 * Username: admin / Password: admin 



## Usage
* You can connect to each VM with `vagrant ssh` and the name of the VM you want to connect to
* Each VM is called RHCSx where x starts with 1 and there is also one RHS-C VM for USM
 * RHCS1 is your first VM and it counts up depending on the amount of VMs you spawn
* There are also other vagrant commands you should check out!
 * Try vagrant -h to find out about them
* *Always make sure you are in the git repo - vagrant only works in there!*

## Author
[Christopher Blum](mailto:cblum@redhat.com) - <cblum@redhat.com>
Storage Consultant @ Red Hat

[Stephan Hohn](mailto:shohn@redhat.com) - <shohn@redhat.com>
Senior Storage Consultant @ Red Hat

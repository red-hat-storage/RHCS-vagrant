#!/bin/bash
#
# The script relies on the auto osd discovery feature, so we at least expect 2 raw devices
# to work properly.
#set -e

cd /vagrant/ceph-ansible

if [[ -z $1 ]]; then
  CEPH_BRANCH_DEFAULT=master
else
  CEPH_BRANCH_DEFAULT=$1
fi
CEPH_BRANCH=${CEPH_BRANCH:-$CEPH_BRANCH_DEFAULT}
SUBNET=$(ip r |grep eth1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}' | head -1)
MON_IP=$(ip -4 -o a | awk '/eth1/ { sub ("/..", "", $4); print $4 }')

cp group_vars/all.sample group_vars/all
cp group_vars/mons.sample group_vars/mons
cp group_vars/osds.sample group_vars/osds
echo '' > roles/ceph-common/tasks/pre_requisites/prerequisite_rh_storage_cdn_install.yml
cp ../ceph-ansible-fixes/activate_osds.yml roles/ceph-osd/tasks/
cp ../ceph-ansible-fixes/check_devices_auto.yml roles/ceph-osd/tasks/


if [[ $EUID -ne 0 ]]; then
    echo "You are NOT running this script as root."
    echo "You should."
    echo "Really."
    echo "PLEASE RUN IT WITH SUDO ONLY :)"
    exit 1
fi

sed -i "s/#osd_auto_discovery: false/osd_auto_discovery: true/" group_vars/osds
sed -i "s/#journal_collocation: false/journal_collocation: true/" group_vars/osds

# sed -i "s/#ceph_dev: false/ceph_dev: true/" group_vars/all
# sed -i "s|#ceph_dev_branch: master|ceph_dev_branch: ${CEPH_BRANCH}|" group_vars/all

sed -i "s/#ceph_rhcs: false/ceph_rhcs: true/" group_vars/all
sed -i "s/#ceph_rhcs_version: 1.3/ceph_rhcs_version: 2/" group_vars/all
sed -i "s/#ceph_rhcs_cdn_install: false/ceph_rhcs_cdn_install: true/" group_vars/all

#sed -i "s/#pool_default_size: 3/pool_default_size: 2/" group_vars/all #<-- does not exist any more?!
# sed -i "s/#monitor_address: 0.0.0.0/monitor_address: ${MON_IP}/" group_vars/all
sed -i "s/#monitor_interface: interface/monitor_interface: eth1/" group_vars/all
sed -i "s/#journal_size: 0/journal_size: 1024/" group_vars/all
sed -i "s|#public_network: 0.0.0.0\/0|public_network: ${SUBNET}|" group_vars/all
# sed -i "s/#common_single_host_mode: true/common_single_host_mode: true/" group_vars/all

cp site.yml.sample site.yml
ansible all -m ping
ansible-playbook site.yml

# If RHCS <=1.3x
# ansible osds -a 'service ceph start osd'

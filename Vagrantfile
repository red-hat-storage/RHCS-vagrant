# -*- mode: ruby -*-
# vi: set ft=ruby :

# Some variables we need below
VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

#################
# Available RHCS base images (1.3.0, 1.3.1, 1.3.2, 2.0.0)
#################

#VBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_vb_RHCS1.3.0.box"
#LVBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_lv_RHCS1.3.0.box"

#VBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_vb_RHCS1.3.1.box"
#LVBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_lv_RHCS1.3.1.box"

#VBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_vb_RHCS1.3.2.box"
#LVBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_lv_RHCS1.3.2.box"

VBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_vb_RHCS2.0.0.box"
LVBOXURL = "http://file.rdu.redhat.com/~cblum/vagrant-storage/packer_lv_RHCS2.0.0.box"

numberOfVMs = 0
numberOfDisks = -1

#################
# General VM settings applied to all VMs
#################
VMCPU = 2
VMMEM = 1500
#################

if ARGV[0] == "up"
  environment = open('vagrant_env.conf', 'w')
  
  print "\n\e[1;37mHow many storage nodes do you want me to provision for you? Default: 2 \e[32m"
  while numberOfVMs < 2 or numberOfVMs > 99
    numberOfVMs = $stdin.gets.strip.to_i
    if numberOfVMs == 0 # The user pressed enter without input or we cannot parse the input to a number
      numberOfVMs = 2
    elsif numberOfVMs < 2
      print "\e[31mYou will need at least 2 ODS nodes for a healthy cluster ;) Try again \e[32m"
    elsif numberOfVMs > 99
      print "\e[31mWe don't support more than 99 VMs - Try again \e[32m"
    end
  end

  print "\e[1;37mHow many disks do you need per storage node? Default: 2 \e[32m"

  while numberOfDisks < 1
    numberOfDisks = $stdin.gets.strip.to_i
    if numberOfDisks == 0 # The user pressed enter without input or we cannot parse the input to a number
      numberOfDisks = 2
    elsif numberOfDisks < 1
      print "\e[31mWe need at least 1 disk ;) Try again \e[32m"
    elsif numberOfDisks > 5
      print "\e[31mWe don't support more than 5 disks - Try again \e[32m"
    end
  end

  environment.puts("# BEWARE: Do NOT modify ANY settings in here or your vagrant environment will be messed up")
  environment.puts(numberOfVMs.to_s)
  environment.puts(numberOfDisks.to_s)

  print "\e[32m\nOK I will provision 1 RHS-C node and #{numberOfVMs} storage nodes for you\nEach storage node will have #{numberOfDisks} disks for ceph\e[37m\n\n"
  system "sleep 1"
else # So that we destroy and can connect to all VMs...
  environment = open('vagrant_env.conf', 'r')

  environment.readline # Skip the comment on top
  numberOfVMs = environment.readline.to_i
  numberOfDisks = environment.readline.to_i

  if ARGV[0] != "ssh-config"
    puts "Detected settings from previous vagrant up:"
    puts "  We deployed #{numberOfVMs} OSD nodes each with #{numberOfDisks} disks"
    puts ""
  end
end

environment.close

# diskNames = ['sda', 'sdb', 'sdc', 'sdd', 'sde']
diskNames = ['vda', 'vdb', 'vdc', 'vdd', 'vde']

hostsFile = "192.168.15.200 RHS-C RHSC\n"
(1..numberOfVMs).each do |num|
  hostsFile += "192.168.15.#{( 99 + num).to_s} RHCS#{num.to_s}\n"
end

ansibleHostsFile = "[rhsc]\n  RHSC\n\n[ceph]\n"
(1..numberOfVMs).each do |num|
  ansibleHostsFile += "  RHCS#{num.to_s}\n"
end

def vBoxAttachDisks(numDisk, provider, boxName)
  for i in 1..numDisk.to_i
    file_to_disk = File.join(VAGRANT_ROOT, 'disks', ( boxName + '-' +'disk' + i.to_s + '.vdi' ))
    unless File.exist?(file_to_disk)
      provider.customize ['createhd', '--filename', file_to_disk, '--size', 100 * 1024] # 30GB brick device
    end
    provider.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', i, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  end
end

def lvAttachDisks(numDisk, provider)
  for i in 1..numDisk.to_i
    provider.storage :file, :size => '100G'
  end
end

# Vagrant config section starts here
Vagrant.configure(2) do |config|

  (1..numberOfVMs).each do |vmNum|
    config.vm.define "RHCS#{vmNum.to_s}" do |copycat|
      # This will be the private VM-only network where Ceph traffic will flow
      copycat.vm.network "private_network", ip: ( "192.168.15." + (99 + vmNum).to_s ), model_type: "rtl8139"
      copycat.vm.hostname = "RHCS#{vmNum.to_s}"

      copycat.vm.provider "virtualbox" do |vb, override|
        override.vm.box = VBOXURL

        # Don't display the VirtualBox GUI when booting the machine
        vb.gui = false
        vb.name = "RHCS#{vmNum.to_s}-v2.0"
      
        # Customize the amount of memory and vCPU in the VM:
        vb.memory = VMMEM
        vb.cpus = VMCPU

        vBoxAttachDisks( numberOfDisks, vb, "RHCS#{vmNum.to_s}" )
      end

      copycat.vm.provider "libvirt" do |lv, override|
        override.vm.box = LVBOXURL
        override.vm.synced_folder '.', '/vagrant', type: 'rsync'
      
        # Customize the amount of memory and vCPU in the VM:
        lv.memory = VMMEM
        lv.cpus = VMCPU

        lvAttachDisks( numberOfDisks, lv )
      end

      copycat.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "rhsc-storage.yml"
        ansible.install = false
        ansible.verbose = true
      end

      copycat.vm.post_up_message = "\e[37mBuilding of this VM is finished \nYou can access it now with: \nvagrant ssh RHCS#{vmNum.to_s}\e[32m"

    end
  end
  

  config.vm.define "RHS-C" do |mainbox|
    # This will be the private VM-only network where Ceph traffic will flow
    mainbox.vm.network "private_network", ip: '192.168.15.200'
    # Port forward for Web interface (HTTP)
    mainbox.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: '*'
    # Port forward for Web interface (HTTPS)
    mainbox.vm.network "forwarded_port", guest: 10443, host: 10443, host_ip: '*'
    # # Port forward for Rest API
    # mainbox.vm.network "forwarded_port", guest: 8181, host: 8181
    # mainbox.vm.network "forwarded_port", guest: 8081, host: 8081
    mainbox.vm.hostname = 'RHS-C'
    
    mainbox.vm.provider "virtualbox" do |vb, override|
      override.vm.box = VBOXURL

      # Don't display the VirtualBox GUI when booting the machine
      vb.gui = false
      vb.name = "RHS-C"
    
      # Customize the amount of memory and vCPU in the VM:
      vb.memory = 2500
      vb.cpus = VMCPU

      vBoxAttachDisks( numberOfDisks, vb, 'RHS-C' )
    end
    
    mainbox.vm.provider "libvirt" do |lv, override|
      override.vm.box = LVBOXURL
      override.vm.synced_folder '.', '/vagrant', type: 'rsync'
    
      # Customize the amount of memory and vCPU in the VM:
      lv.memory = 2500
      lv.cpus = VMCPU

      lvAttachDisks( numberOfDisks, lv )
    end

    mainbox.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "rhsc-controller.yml"
      ansible.install = false
      ansible.verbose = true
      # ansible.verbose = 'vvvv'
    end
    
    csshCmd = "vagrant ssh-config > ssh_conf; csshx --ssh_args '-F #{VAGRANT_ROOT}/ssh_conf' RHS-C "
    (1..numberOfVMs).each do |num|
      csshCmd += "RHCS#{num.to_s} "
    end

    mainbox.vm.post_up_message = "If you don't see any text below, it's because the text color is white ;)\n\e[37mBuilding of this VM is finished \nYou can access it now with: \nvagrant ssh RHS-C\nI already connected the RHCS nodes with gluster peer probe for your convenience\n\n csshX Command line:\n#{csshCmd}\e[32m"

  end


  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.

  # The flow is outside->in so that this will run before all node specific Shell skripts mentioned above!
  config.vm.provision "shell", inline: <<-SHELL
    echo '#{hostsFile}' | sudo tee -a /etc/hosts
    echo 'Host *' | sudo tee -a /root/.ssh/config
    echo ' StrictHostKeyChecking no' | sudo tee -a /root/.ssh/config
    echo ' UserKnownHostsFile=/dev/null' | sudo tee -a /root/.ssh/config
  SHELL

  # Fix broken detection for ansible 2+ in vagrant 1.8.1 :(
  # https://github.com/mitchellh/vagrant/issues/6793
  config.vm.provision :shell, inline: <<-SCRIPT
    GALAXY=/usr/local/bin/ansible-galaxy
    echo '#!/usr/bin/env bash
    /usr/bin/ansible-galaxy "$@"
    exit 0
    ' | sudo tee $GALAXY
    sudo chmod 0755 $GALAXY
  SCRIPT

end

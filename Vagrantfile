# -*- mode: ruby -*-
# vi: set ft=ruby :

# Some variables we need below
VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

#################
# Set RHCS version
RHCS_VERSION = "RHCS2.0.0"

# Currently available versions:
# RHCS1.3.0
# RHCS1.3.1
# RHCS1.3.2
# RHCS1.3.3
# RHCS2.0.0
#################

#################
# General VM settings applied to all VMs
#################
VMCPU = 2
VMMEM = 1500
#################



numberOfVMs = 0
numberOfDisks = -1
if ARGV[0] == "up"
  environment = open('vagrant_env.conf', 'w')
  
  print "\n\e[1;37mHow many OSD nodes do you want me to provision for you? Default: 2 \e[32m"
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

  print "\e[1;37mHow many disks do you need per OSD node? Default: 2 \e[32m"

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

  while true
    print "\n\e[1;37mDo you want me to set the ceph cluster up? Default: yes \e[32m"
    answer = $stdin.gets.strip.to_s.downcase
    if answer == "" or answer == "y" or answer == "yes"
      provisionEnvironment = true
      break
    elsif answer == "n" or answer == "no"
      provisionEnvironment = false
      break
    end
  end


  environment.puts("# BEWARE: Do NOT modify ANY settings in here or your vagrant environment will be messed up")
  environment.puts(numberOfVMs.to_s)
  environment.puts(numberOfDisks.to_s)

  print "\e[32m\nOK I will provision 1 MON node and #{numberOfVMs} OSD nodes for you\nEach OSD node will have #{numberOfDisks} disks for OSD daemons\e[37m\n\n"
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

hostsFile = "192.168.15.200 MON\n"
(1..numberOfVMs).each do |num|
  hostsFile += "192.168.15.#{( 99 + num).to_s} OSD#{num.to_s}\n"
end

ansibleHostsFile = "[mons]\n  MON\n\n[osds]\n"
(1..numberOfVMs).each do |num|
  ansibleHostsFile += "  OSD#{num.to_s}\n"
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
  config.vm.box_url = "http://file.rdu.redhat.com/~cblum/vagrant-storage/#{RHCS_VERSION}.json"
  
  (1..numberOfVMs).each do |vmNum|
    config.vm.define "OSD#{vmNum.to_s}" do |copycat|
      # This will be the private VM-only network where Ceph traffic will flow
      copycat.vm.network "private_network", ip: ( "192.168.15." + (99 + vmNum).to_s ), model_type: "rtl8139"
      copycat.vm.hostname = "OSD#{vmNum.to_s}"

      copycat.vm.provider "virtualbox" do |vb, override|
        override.vm.box = RHCS_VERSION

        # Don't display the VirtualBox GUI when booting the machine
        vb.gui = false
        vb.name = "OSD#{vmNum.to_s}-v1.3"
      
        # Customize the amount of memory and vCPU in the VM:
        vb.memory = VMMEM
        vb.cpus = VMCPU

        vBoxAttachDisks( numberOfDisks, vb, "OSD#{vmNum.to_s}" )
      end

      copycat.vm.provider "libvirt" do |lv, override|
        override.vm.box = RHCS_VERSION
      
        # Customize the amount of memory and vCPU in the VM:
        lv.memory = VMMEM
        lv.cpus = VMCPU

        lvAttachDisks( numberOfDisks, lv )
      end
      copycat.vm.post_up_message = "\e[37mBuilding of this VM is finished \nYou can access it now with: \nvagrant ssh OSD#{vmNum.to_s}\e[32m"

    end
  end


  config.vm.define "MON" do |mainbox|
    # This will be the private VM-only network where Ceph traffic will flow
    mainbox.vm.network "private_network", ip: '192.168.15.200'
    mainbox.vm.hostname = 'MON'
    
    mainbox.vm.provider "virtualbox" do |vb, override|
      override.vm.box = RHCS_VERSION

      # Don't display the VirtualBox GUI when booting the machine
      vb.gui = false
      vb.name = "MON"
    
      # Customize the amount of memory and vCPU in the VM:
      vb.memory = VMMEM
      vb.cpus = VMCPU

      vBoxAttachDisks( numberOfDisks, vb, 'MON' )
    end
    
    mainbox.vm.provider "libvirt" do |lv, override|
      override.vm.box = RHCS_VERSION
      override.vm.synced_folder '.', '/vagrant', type: 'rsync'
    
      # Customize the amount of memory and vCPU in the VM:
      lv.memory = VMMEM
      lv.cpus = VMCPU

      lvAttachDisks( numberOfDisks, lv )
    end

    config.vm.provision "shell", inline: <<-SHELL
      echo '#{ansibleHostsFile}' | sudo tee -a /etc/ansible/hosts
    SHELL

    command = 'sudo chmod +x /vagrant/deploy_ceph_with_ansible.sh;'
    command += 'sudo /vagrant/deploy_ceph_with_ansible.sh;'

    # If the user wishes no automatic deployment -> Forget the previous steps
    if !provisionEnvironment
      puts "#Skipping automated ceph deployment"
      command = ''
    end

    mainbox.vm.provision "shell",
      inline: command
    
    csshCmd = "vagrant ssh-config > ssh_conf; csshx --ssh_args '-F #{VAGRANT_ROOT}/ssh_conf' MON "
    (1..numberOfVMs).each do |num|
      csshCmd += "OSD#{num.to_s} "
    end

    mainbox.vm.post_up_message = "If you don't see any text below, it's because the text color is white ;)\n\e[37mBuilding of this VM is finished \nYou can access it now with: \nvagrant ssh MON\nI already connected the RHCS nodes with gluster peer probe for your convenience\n\n csshX Command line:\n#{csshCmd}\e[32m"

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

end

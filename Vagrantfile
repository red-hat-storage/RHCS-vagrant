# -*- mode: ruby -*-
# vi: set ft=ruby :

# Some variables we need below
VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

#################
# Disable parallel runs - breaks ansible call
#################
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

#################
# General VM settings applied to all VMs
#################
VMCPU = 1         # number of cores per VM
VMMEM = 1024      # amount of memory in MB per VM
VMDISK = 30       # size of brick disks in GB per VM

#################
# Available RHCS base images (3.0)
#################

rhcsBox = {
  "default" => {
    :virtualbox => "file:///tmp/rhcs-rhel-7/virtualbox-rhcs-node-3.0-rhel-7.box",
    :libvirt => "file:///tmp/rhcs-rhel-7/libvirt-rhcs-node-3.0-rhel-7.box"
  },
  "3.0" => {
    :virtualbox => "file:///tmp/rhcs-rhel-7/virtualbox-rhcs-node-3.0-rhel-7.box",
    :libvirt => "file:///tmp/rhcs-rhel-7/libvirt-rhcs-node-3.0-rhel-7.box"
  }
}

numberOf = {
  'OSDs'    =>  { :value => -1, :min => 2, :default => 2 },
  'disks'   =>  { :value => -1, :min => 2, :default => 2 },
  'MONs'    =>  { :value => -1, :min => 1, :default => 1 },
  'RGWs'    =>  { :value => -1, :min => 0, :default => 0 },
  'MDSs'    =>  { :value => -1, :min => 0, :default => 0 },
  'NFSs'    =>  { :value => -1, :min => 0, :default => 0 },
  'iSCSI-GWs'    =>  { :value => -1, :min => 0, :default => 0 },
  'Clients' =>  { :value => -1, :min => 0, :default => 0 }
}

clusterType = {
  "default" => { :type => "RPM" },
  "rpm-based" => { :type => "RPM" },
  "containerized" => { :type => "CSD" },
}

rhcsVbox = rhcsBox["default"][:virtualbox]
rhcsLbox = rhcsBox["default"][:libvirt]
clusterInit = -1
clusterInstall = ""

if ARGV[0] == "up"

  while true
    print "\n\e[1;37mWhich version of Ceph do you want to use? [3.0] \e[32m"
    print "\n\e[1;37mVersions available: \e[32m\n"
    rhcsBox.each { |key, value|
      puts ("  * " + key) if not key == "default"
    }
    respone = $stdin.gets.strip.to_s.downcase
    if respone == ""
      break
    elsif boxURL.key?(respone)
      rhcsVbox = rhcsBox[respone][:virtualbox]
      rhcsLbox = rhcsBox[respone][:libvirt]
      break
    else
      puts "Please enter a valid version!"
    end
  end

  numberOf.each { |name, settings|
    print "\n\e[1;37mHow many #{name} do you want me to provision for you? [#{settings[:default]}] \e[32m"
    while settings[:value] < settings[:min]
      response = $stdin.gets.strip
      if response == "0"
        settings[:value] = 0
      elsif response == "" or response.to_i == 0 # The user pressed enter without input or we cannot parse the input to a number
        settings[:value] = settings[:default]
      else
        settings[:value] = response.to_i
      end

      if settings[:value] < settings[:min]
        print "\e[31mYou will need at least #{settings[:min]} #{name}. Try again! \e[32m"
      end
    end
  }

  while clusterInit == -1
    print "\n\e[1;37mDo you want me to initialize the cluster for you? [no] \e[32m"
    response = $stdin.gets.strip.to_s.downcase
    if response == "y" or response == "yes"
      clusterInit = 1
    elsif response == "" or response == "n" or response == "no"
      clusterInit = 0
    else
      print "\e[31mPlease enter 'yes' or 'no'\e[32m"
    end
  end

  while clusterInstall == ""
    print "\n\e[1;37mPlease choose your installation type [%s] \e[32m" % clusterType["default"][:type]

    clusterType.each { |key, value|
      puts ("  * " + key) if not key == "default"
    }

    response = $stdin.gets.strip.to_s.downcase

    if response == ""
      clusterInstall = clusterType["default"][:type]
    elsif clusterType.key?(response)
      clusterInstall = clusterType[response][:type]
    else
      print "\e[31mPlease select a valid installation type!\e[32m"
    end
  end

  print "\e[32m\nOK I will provision:\n"
  environment = open('vagrant_env.conf', 'w')
  environment.puts("# BEWARE: Do NOT modify ANY settings in here or your vagrant environment will be messed up")
  numberOf.each { |name, settings|
    environment.puts(settings[:value].to_s)
    if name == 'disks'
      print "  * #{settings[:value]} disks for OSD daemons in every OSD VM\n"
    else
      print "  * #{settings[:value]} #{name}\n"
    end
  }
  environment.puts(clusterInstall)

  print "\e[37m\n\n"

  system "sleep 1"
else # So that we destroy and can connect to all VMs...
  environment = open('vagrant_env.conf', 'r')

  environment.readline # Skip the comment in the first line
  numberOf.each { |name, settings|
    settings[:value] = environment.readline.to_i
  }
  clusterInstall = environment.readline.to_i
end

environment.close


def vBoxAttachDisks(numDisk, provider, boxName)
  for i in 1..numDisk.to_i
    file_to_disk = File.join(VAGRANT_ROOT, 'disks', ( boxName + '-' +'disk' + i.to_s + '.vdi' ))
    unless File.exist?(file_to_disk)
      provider.customize ['createhd', '--filename', file_to_disk, '--size', VMDISK * 1024] # 30GB brick device
    end
    provider.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', i, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  end
end

def lvAttachDisks(numDisk, provider)
  for i in 1..numDisk.to_i
    provider.storage :file, :bus => 'virtio', :size => VMDISK
  end
end

cluster={}
numberOf["OSDs"][:value].times       { |n| cluster["OSD#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "osds" } }
numberOf["RGWs"][:value].times       { |n| cluster["RGW#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "rgws" } }
numberOf["MDSs"][:value].times       { |n| cluster["MDS#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "mdss" } }
numberOf["Clients"][:value].times    { |n| cluster["CLIENT#{n}"] = { :cpus => VMCPU, :mem => VMMEM, :group => "clients" } }
numberOf["NFSs"][:value].times       { |n| cluster["NFS#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "nfss" } }
numberOf["iSCSI-GWs"][:value].times  { |n| cluster["ISCSI#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "nfss" } }
numberOf["MONs"][:value].times       { |n| cluster["MON#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "mons" } }


Vagrant.configure(2) do |config|

  cluster.each_with_index do |(hostname, info), index|
    config.vm.define hostname do |machine|

      machine.vm.hostname = hostname
      machine.vm.synced_folder ".", "/vagrant", disabled: true

      machine.vm.provider "virtualbox" do |vb, override|
        override.vm.box = rhcsVbox

        # private VM-only network where ceph client traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false

        # private VM-only network, on specified 10.0.0.x subnet, where ceph cluster traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false, ip: "172.16.0.1"

        vb.name = hostname
        vb.memory = info[:mem]
        vb.cpus = info[:cpus]

        # Make this a linked clone for cow snapshot based root disks
        vb.linked_clone = true

        # Don't display the VirtualBox GUI when booting the machine
        vb.gui = false

        # Accelerate SSH / Ansible connections (https://github.com/mitchellh/vagrant/issues/1807)
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

        if info[:group] == "osds"
          vBoxAttachDisks( numberOf["disks"][:value], vb, hostname )
        end
      end

      machine.vm.provider "libvirt" do |lv, override|
        # override.vm.box = lvBoxURL
        # override.vm.synced_folder '.', '/vagrant', type: 'rsync', rsync__args: ["--verbose", "--archive", "--delete"]
        # lv.memory = info[:mem]
        # lv.cpus = info[:cpus]
        # lvAttachDisks( numberOf["disks"][:value], lv )
      end

      # provision nodes with ansible
      if index == cluster.size - 1

        machine.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          ansible.playbook = "ansible/prepare-environment.yml"
        end

        machine.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          ansible.extra_vars = { install_type: "rpm" }
          ansible.groups = {
            'mons'         => (0...numberOf["MONs"][:value]).map    { |j| "MON#{j}" },
            'osds'         => (0...numberOf["OSDs"][:value]).map    { |j| "OSD#{j}" },
            'mdss'         => (0...numberOf["MDSs"][:value]).map    { |j| "MDS#{j}" },
            'rgws'         => (0...numberOf["NFSs"][:value]).map    { |j| "RGW#{j}" },
            'nfss'         => (0...numberOf["NFSs"][:value]).map    { |j| "NFS#{j}" },
            'iscsi-gws'         => (0...numberOf["iSCSI-GWs"][:value]).map    { |j| "ISCSI#{j}" },
            'clients'      => (0...numberOf["Clients"][:value]).map { |j| "CLIENT#{j}" },
            'rhcs-nodes:children' => ['mons','osds','mdss','rgws','nfss','iscsi-gws','clients']
          }
          ansible.playbook = "ansible/prepare-ceph.yml"
        end

        # machine.vm.provision :ansible_local do |ansible|
        #   ansible.provisioning_path = '/vagrant/ceph-ansible/'
        #   ansible.playbook = "/vagrant/ceph-ansible/site.yml.sample"
        #   ansible.install = false
        #   # ansible.sudo = true
        #   # ansible.verbose = true
        #   ansible.verbose = 'vvvv'
        #   ansible.limit = 'all'
        #   ansible.groups = {
        #     'mons'         => (0...numberOf["MONs"][:value]).map    { |j| "MON#{j}" },
        #     'osds'         => (0...numberOf["OSDs"][:value]).map    { |j| "OSD#{j}" },
        #     'mdss'         => (0...numberOf["MDSs"][:value]).map    { |j| "MDS#{j}" },
        #     'rgws'         => (0...numberOf["RGWs"][:value]).map    { |j| "RGW#{j}" },
        #     'clients'      => (0...numberOf["clients"][:value]).map { |j| "Client#{j}" }
        #   }
        # end # end provision
      end #end if

    end # end config

  end #end cluster

end

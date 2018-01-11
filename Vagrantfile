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
VMMEM = 1536      # amount of memory in MB per VM
VMDISK = 30       # size of brick disks in GB per VM

#################
# Available RHCS base images (3.0)
#################

rhcsBox = {
  "default" => {
    :virtualbox => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/virtualbox-rhcs-node-3.0-rhel-7.box",
    :libvirt => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/libvirt-rhcs-node-3.0-rhel-7.box"
  },
  "3.0" => {
    :virtualbox => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/virtualbox-rhcs-node-3.0-rhel-7.box",
    :libvirt => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/libvirt-rhcs-node-3.0-rhel-7.box"
  }
}

metricsBox = {
  :virtualbox => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/virtualbox-metrics-server-3.0-rhel-7.box",
  :libvirt => "http://file.str.redhat.com/~dmesser/rhcs-vagrant/libvirt-metrics-server-3.0-rhel-7.box"
}

numberOf = {
  'OSDs'    =>  { :value => -1, :min => 2, :default => 2 },
  'disks'   =>  { :value => -1, :min => 2, :default => 2 },
  'MONs'    =>  { :value => -1, :min => 1, :default => 1 },
  'RGWs'    =>  { :value => -1, :min => 0, :default => 0 },
  'MDSs'    =>  { :value => -1, :min => 0, :default => 0 },
  'NFSs'    =>  { :value => -1, :min => 0, :default => 0 },
  # 'iSCSI-GWs'    =>  { :value => -1, :min => 0, :default => 0 },
  'Clients' =>  { :value => -1, :min => 0, :default => 0 }
}

clusterType = {
  "default" => { :type => "rpm-based" },
  "rpm-based" => { :type => "rpm" },
  "containerized" => { :type => "csd" },
}

rhcsVbox = rhcsBox["default"][:virtualbox]
rhcsLbox = rhcsBox["default"][:libvirt]
clusterInit = -1
clusterInstall = ""
osdBackend = ""
metricsInstall = -1

if ARGV[0] == "up"

  while true
    print "\n\e[1;37mVersions available: \e[32m\n"
    rhcsBox.each { |key, value|
      puts ("  * " + key) if not key == "default"
    }
    print "\n\e[1;37mWhich version of Ceph do you want to use? [3.0] \e[32m"

    response = $stdin.gets.strip.to_s.downcase
    if response == ""
      break
    elsif boxURL.key?(response)
      rhcsVbox = rhcsBox[response][:virtualbox]
      rhcsLbox = rhcsBox[response][:libvirt]
      break
    else
      puts "Please enter a valid version!"
    end
  end



  while clusterInstall == ""
    print "\n\e[1;37mInstallation Types available: \e[32m\n"

    clusterType.each { |key, value|
      puts ("  * " + key) if not key == "default"
    }

    print "\n\e[1;37mPlease choose your installation type [%s] \e[32m" % clusterType["default"][:type]

    response = $stdin.gets.strip.to_s.downcase

    if response == ""
      defaultInstallType = clusterType["default"][:type]
      clusterInstall = clusterType[defaultInstallType][:type]
    elsif clusterType.key?(response)
      clusterInstall = clusterType[response][:type]
    else
      print "\e[31mPlease select a valid installation type!\e[32m"
    end
  end

  while osdBackend == ""
    print "\n\e[1;37mOSD Backend Types available: \e[32m\n"

    ["filestore", "bluestore"].each { |value|
      puts ("  * " + value)
    }

    print "\n\e[1;37mWhat type of OSD backend do you want to use? [filestore] \e[32m"
    response = $stdin.gets.strip.to_s.downcase
    if response == ""
      osdBackend = "filestore"
      break
    elsif ["filestore", "bluestore"].include?(response)
      osdBackend = response
      break
    else
      puts "Please enter a valid backend type. Try again!"
    end
  end

  if clusterInstall == clusterType["rpm-based"][:type]
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
  elsif clusterInstall == clusterType["containerized"][:type]
    numberOf.take(2).each { |name, settings|
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
      end

      if settings[:value] < settings[:min]
        print "\e[31mYou will need at least #{settings[:min]} #{name}. Try again! \e[32m"
      end
    }

    numberOf.drop(2).tap(&:pop).each { |name, settings|

      # if name == "iSCSI-GWs" # ceph-ansible does not support containerized iSCSI yet
      #   settings[:value] = 0
      #   next
      # end

      print "\n\e[1;37mHow many #{name} do you want to co-locate? [#{settings[:default]}] \e[32m"

      while settings[:value] < settings[:min] or settings[:value] > numberOf["OSDs"][:value]
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
        elsif settings[:value] > numberOf["OSDs"][:value]
          print "\e[31mYou cannot have more than #{numberOf['OSDs'][:value]} #{name}. Try again! \e[32m"
        end
      end
    }

    print "\n\e[1;37mDo you want to provision a client? [no] \e[32m"

    while numberOf["Clients"][:value] < numberOf["Clients"][:min]
      response = $stdin.gets.strip.to_s.downcase

      if response == "no" or response == "n" or response == "" # The user pressed enter without input
        numberOf["Clients"][:value] = 0
      elsif response == "yes" or response == "y"
        numberOf["Clients"][:value] = 0
      else
        print "\e[31mPlease enter 'yes' or 'no'!"
        next
      end
    end
  end

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

  if clusterInit == 1 and clusterInstall == clusterType["rpm-based"][:type]
    while metricsInstall == -1
      print "\n\e[1;37mDo you want me set up ceph-metrics for you? [no] \e[32m"
      response = $stdin.gets.strip.to_s.downcase
      if response == "y" or response == "yes"
        metricsInstall = 1
      elsif response == "" or response == "n" or response == "no"
        metricsInstall = 0
      else
        print "\e[31mPlease enter 'yes' or 'no'\e[32m"
      end
    end
  end

  print "\e[32m\nOK I will provision:\n\n"
  environment = open('vagrant_env.conf', 'w')
  environment.puts("# BEWARE: Do NOT modify ANY settings in here or your vagrant environment will be messed up")
  numberOf.each { |name, settings|
    environment.puts(settings[:value].to_s)
    if name == 'disks'
      print "  * #{settings[:value]} disks for OSD daemons (#{osdBackend}) in every OSD VM\n"
    elsif clusterInstall == clusterType["containerized"][:type] and name != "OSDs" and name != "Clients"
      print "  * #{settings[:value]} #{name} (co-located with OSD)\n"
    else
      print "  * #{settings[:value]} #{name}\n"
    end
  }

  if clusterInit == 1
    print "\e[32m\nI will also initialize the cluster for you using ceph-ansible"

    if metricsInstall == 1
      print " and deploy ceph-metrics in a separate VM"
    end

    print "\n"
  else
    print "\e[32m\nI will NOT initialize the cluster but leave an appropriate ceph-ansible setup for your convenience\n"
  end

  environment.puts(clusterInit.to_i)
  environment.puts(clusterInstall.to_s)
  environment.puts(osdBackend.to_s)
  environment.puts(metricsInstall.to_s)

  print "\e[37m\n\n"

  system "sleep 1"
else # So that we destroy and can connect to all VMs...
  environment = open('vagrant_env.conf', 'r')

  environment.readline # Skip the comment in the first line
  numberOf.each { |name, settings|
    settings[:value] = environment.readline.to_i
  }
  clusterInit = environment.readline.strip.to_i
  clusterInstall = environment.readline.strip.to_s
  osdBackend = environment.readline.strip.to_s
  metricsInstall = environment.readline.strip.to_i
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

if clusterInstall == clusterType["rpm-based"][:type]
  numberOf["OSDs"][:value].times       { |n| cluster["OSD#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "osds" } }
  numberOf["RGWs"][:value].times       { |n| cluster["RGW#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "rgws" } }
  numberOf["MDSs"][:value].times       { |n| cluster["MDS#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "mdss" } }
  numberOf["Clients"][:value].times    { |n| cluster["CLIENT#{n}"] = { :cpus => VMCPU, :mem => VMMEM, :group => "clients" } }
  numberOf["NFSs"][:value].times       { |n| cluster["NFS#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "nfss" } }
  # numberOf["iSCSI-GWs"][:value].times  { |n| cluster["ISCSI#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "nfss" } }
  numberOf["MONs"][:value].times       { |n| cluster["MON#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "mons" } }
elsif clusterInstall == clusterType["containerized"][:type]
  numberOf["OSDs"][:value].times       { |n| cluster["OSD#{n}"]    = { :cpus => VMCPU, :mem => VMMEM, :group => "osds" } }
  numberOf["Clients"][:value].times    { |n| cluster["CLIENT#{n}"] = { :cpus => VMCPU, :mem => VMMEM, :group => "clients" } }
end


Vagrant.configure(2) do |config|

  cluster.each_with_index do |(hostname, info), index|
    config.vm.define hostname do |machine|

      machine.vm.hostname = hostname
      machine.vm.synced_folder ".", "/vagrant", disabled: true

      machine.vm.provider "virtualbox" do |vb, override|
        override.vm.box = "RHCS-vagrant-virtualbox"
        override.vm.box_url = rhcsVbox

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
        override.vm.box = "RHCS-vagrant-libvirt"
        override.vm.box_url = rhcsLbox

        lv.storage_pool_name = ENV['LIBVIRT_STORAGE_POOL'] || 'default'

        # Set VM resources
        lv.memory = info[:mem]
        lv.cpus = info[:cpus]

        # private VM-only network where ceph client traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false

        # private VM-only network, on specified 10.0.0.x subnet, where ceph cluster traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false, ip: "172.16.0.1"

        # Use virtio device drivers
        lv.nic_model_type = "virtio"
        lv.disk_bus = "virtio"

        # connect to local libvirtd daemon as root
        lv.username = "root"

        if info[:group] == "osds"
          lvAttachDisks( numberOf["disks"][:value], lv )
        end
      end

      # provision nodes with ansible
      if index == cluster.size - 1

        machine.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          ansible.playbook = "ansible/prepare-environment.yml"
        end

        machine.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          ansible.extra_vars = { install_type: clusterInstall, osd_type: osdBackend }

          if clusterInstall == clusterType["rpm-based"][:type]
            ansible.groups = {
              'mons'         => (0...numberOf["MONs"][:value]).map    { |j| "MON#{j}" },
              'osds'         => (0...numberOf["OSDs"][:value]).map    { |j| "OSD#{j}" },
              'mdss'         => (0...numberOf["MDSs"][:value]).map    { |j| "MDS#{j}" },
              'rgws'         => (0...numberOf["RGWs"][:value]).map    { |j| "RGW#{j}" },
              'nfss'         => (0...numberOf["NFSs"][:value]).map    { |j| "NFS#{j}" },
              # 'iscsi-gws'         => (0...numberOf["iSCSI-GWs"][:value]).map    { |j| "ISCSI#{j}" },
              'clients'      => (0...numberOf["Clients"][:value]).map { |j| "CLIENT#{j}" },
              'rhcs-nodes:children' => ['mons','osds','mdss','rgws','nfss','iscsi-gws','clients']
            }
          elsif clusterInstall == clusterType["containerized"][:type]
            ansible.groups = {
              'mons'         => (0...numberOf["MONs"][:value]).map    { |j| "OSD#{j}" },
              'osds'         => (0...numberOf["OSDs"][:value]).map    { |j| "OSD#{j}" },
              'mdss'         => (0...numberOf["MDSs"][:value]).map    { |j| "OSD#{j}" },
              'rgws'         => (0...numberOf["RGWs"][:value]).map    { |j| "OSD#{j}" },
              'nfss'         => (0...numberOf["NFSs"][:value]).map    { |j| "OSD#{j}" },
              # 'iscsi-gws'         => (0...numberOf["iSCSI-GWs"][:value]).map    { |j| "OSD#{j}" },
              'clients'      => (0...numberOf["Clients"][:value]).map { |j| "OSD#{j}" },
              'rhcs-nodes:children' => ['mons','osds','mdss','rgws','nfss','iscsi-gws','clients']
            }
          end
          ansible.playbook = "ansible/prepare-ceph.yml"
        end

        if clusterInit == 1
          machine.vm.provision :ansible_local do |ansible_local|
            ansible_local.limit = "all"
            ansible_local.provisioning_path = "/usr/share/ceph-ansible"
            ansible_local.inventory_path = "/etc/ansible/hosts"

            if clusterInstall == clusterType["rpm-based"][:type]
              ansible_local.playbook = "site.yml.sample"
            elsif clusterInstall == clusterType["containerized"][:type]
              ansible_local.playbook = "site-docker.yml.sample"
            end
          end
        end # end clusterinit
      end #end provisioning

    end # end config

  end #end cluster

  if metricsInstall == 1 and clusterInstall == clusterType["rpm-based"][:type]
    config.vm.define "METRICS" do |machine|

      machine.vm.hostname = "METRICS"
      machine.vm.synced_folder ".", "/vagrant", disabled: true

      machine.vm.provider "virtualbox" do |vb, override|
        override.vm.box = "RHCS-metrics-vagrant-virtualbox"
        override.vm.box_url = metricsBox[:virtualbox]

        # private VM-only network where ceph client traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false

        vb.name = "METRICS"
        vb.memory = VMMEM
        vb.cpus = VMCPU

        # Make this a linked clone for cow snapshot based root disks
        vb.linked_clone = true

        # Don't display the VirtualBox GUI when booting the machine
        vb.gui = false

        # Accelerate SSH / Ansible connections (https://github.com/mitchellh/vagrant/issues/1807)
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      end

      machine.vm.provider "libvirt" do |lv, override|
        override.vm.box = "RHCS-metrics-vagrant-libvirt"
        override.vm.box_url = metricsBox[:libvirt]

        lv.storage_pool_name = ENV['LIBVIRT_STORAGE_POOL'] || 'default'

        # Set VM resources
        lv.memory = VMMEM
        lv.cpus = VMCPU

        # private VM-only network where ceph client traffic will flow
        override.vm.network "private_network", type: "dhcp", nic_type: "virtio", auto_config: false

        # Use virtio device drivers
        lv.nic_model_type = "virtio"
        lv.disk_bus = "virtio"

        # connect to local libvirtd daemon as root
        lv.username = "root"
      end

      machine.vm.provision :ansible do |ansible|
        ansible.limit = "all"
        ansible.playbook = "ansible/prepare-environment.yml"
      end

      machine.vm.provision :ansible do |ansible|
        ansible.groups = { "metrics" => "METRICS" }
        ansible.limit = "all"
        ansible.playbook = "ansible/prepare-metrics.yml"
      end
    end
  end
end

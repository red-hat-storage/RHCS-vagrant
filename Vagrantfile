# -*- mode: ruby -*-
# vi: set ft=ruby :

# Some variables we need below
VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

#################
# Available RHCS base images (1.3.0, 1.3.1, 1.3.2, 2.0.0)
#################

boxURL = {
  "default" => {
    :name => "RHCS2.0.0"
  },
  "1.3.0" => {
    :name => "RHCS1.3.0"
  },
  "1.3.1" => {
    :name => "RHCS1.3.1"
  },
  "1.3.2" => {
    :name => "RHCS1.3.2"
  },
  "1.3.3" => {
    :name => "RHCS1.3.3"
  },
  "2.0.0" => {
    :name => "RHCS2.0.0"
  }
}

RHCS_VERSION = boxURL["default"][:name]

numberOf = {
  'OSDs' =>     { :value => -1, :min => 2, :max => 99, :default => 2 },
  'disks' =>    { :value => -1, :min => 2, :max => 9,  :default => 2 },
  'MONs' =>     { :value => -1, :min => 1, :max => 6,  :default => 1 },
  'RGWs' =>     { :value => -1, :min => 0, :max => 9,  :default => 0 },
  'MDSs' =>     { :value => -1, :min => 0, :max => 9,  :default => 0 },
  'clients' =>  { :value => -1, :min => 0, :max => 19, :default => 0 }
}

#################
# General VM settings applied to all VMs
#################
SUBNET = "192.168.15."
#################

if ARGV[0] == "up"
  
  while true
    print "\n\e[1;37mWhich version of Ceph do you want to use? Default: 2.0.0 \e[32m"
    print "\n\e[1;37mVersions available: \e[32m\n"
    boxURL.each { |key, value|
      puts ("  * " + key) if not key == "default"
    }
    answer = $stdin.gets.strip.to_s.downcase
    if answer == ""
      break
    elsif boxURL.key?(answer)
      RHCS_VERSION = boxURL[answer][:name]
      break
    else
      puts "This version is not available! Please try again..."
    end
  end

  numberOf.each { |name, settings|
    print "\n\e[1;37mHow many #{name} do you want me to provision for you? Default: #{settings[:default]} \e[32m"
    while settings[:value] < settings[:min] or settings[:value] > settings[:max]
      settings[:value] = $stdin.gets.strip.to_i
      if settings[:value] == 0 # The user pressed enter without input or we cannot parse the input to a number
        settings[:value] = settings[:default]
      elsif settings[:value] < settings[:min]
        print "\e[31mYou will need at least #{settings[:min]} #{name} for a healthy cluster ;) Try again \e[32m"
      elsif settings[:value] > settings[:max]
        print "\e[31mWe don't support more than #{settings[:max]} #{name} - Try again \e[32m"
      end
    end
  }
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
  print "\e[37m\n\n"

  system "sleep 1"
else # So that we destroy and can connect to all VMs...
  environment = open('vagrant_env.conf', 'r')

  environment.readline # Skip the comment in the first line
  numberOf.each { |name, settings|
    settings[:value] = environment.readline.to_i
  }
end

environment.close




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

cluster={}
numberOf["OSDs"][:value].times       { |n| cluster["OSD#{n}"]    = { :ip => SUBNET + (n + 100).to_s, :cpus => 1, :mem => 1024, :type => "osds" } }
numberOf["RGWs"][:value].times       { |n| cluster["RGW#{n}"]    = { :ip => SUBNET + (n + 10).to_s,  :cpus => 1, :mem => 1024, :type => "rgws" } }
numberOf["MDSs"][:value].times       { |n| cluster["MDS#{n}"]    = { :ip => SUBNET + (n + 20).to_s,  :cpus => 1, :mem => 1024, :type => "mdss" } }
numberOf["clients"][:value].times    { |n| cluster["Client#{n}"] = { :ip => SUBNET + (n + 30).to_s,  :cpus => 1, :mem => 1024, :type => "clients" } }
numberOf["MONs"][:value].times       { |n| cluster["MON#{n}"]    = { :ip => SUBNET + (n + 2).to_s,   :cpus => 1, :mem => 1024, :type => "mons" } }

hostsFile = ""
cluster.each do |hostname, info|
  hostsFile += "#{info[:ip]} #{hostname}\n"
end

Vagrant.configure(2) do |config|

  # if Vagrant.has_plugin?("vagrant-cachier")
  #   config.cache.scope = :machine
  #   # config.cache.enable :apt
  # end
  config.vm.box_url = "http://file.rdu.redhat.com/~cblum/vagrant-storage/#{RHCS_VERSION}.json"

  cluster.each_with_index do |(hostname, info), index|
    config.vm.define hostname do |cfg|

      cfg.vm.network "private_network", ip: info[:ip]
      cfg.vm.hostname = hostname

      cfg.vm.provider "virtualbox" do |vb, override|
        override.vm.box = RHCS_VERSION
        vb.name = hostname
        vb.memory = info[:mem]
        vb.cpus = info[:cpus]
        vBoxAttachDisks( numberOf["disks"][:value], vb, hostname )
      end

      cfg.vm.provider "libvirt" do |lv, override|
        override.vm.box = RHCS_VERSION
        override.vm.synced_folder '.', '/vagrant', type: 'rsync', rsync__args: ["--verbose", "--archive", "--delete"]
        lv.memory = info[:mem]
        lv.cpus = info[:cpus]
        lvAttachDisks( numberOf["disks"][:value], lv )
      end

      # provision nodes with ansible
      if index == cluster.size - 1 and ( provisionEnvironment or ARGV[0] == "provision" )

        cfg.vm.provision "shell", inline: <<-SHELL
          set -x
          cd /vagrant/ceph-ansible
          echo '' > roles/ceph-common/tasks/pre_requisites/prerequisite_rh_storage_cdn_install.yml
          cp ../ceph-ansible-fixes/activate_osds.yml roles/ceph-osd/tasks/
          cp ../ceph-ansible-fixes/check_devices_auto.yml roles/ceph-osd/tasks/
        SHELL

        cfg.vm.provision :ansible_local do |ansible|
          ansible.provisioning_path = '/vagrant/ceph-ansible/'
          ansible.playbook = "/vagrant/ceph-ansible/site.yml.sample"
          ansible.install = false
          # ansible.sudo = true
          # ansible.verbose = true
          ansible.verbose = 'vvvv'
          ansible.limit = 'all'
          ansible.groups = {
            'mons'         => (0...numberOf["MONs"][:value]).map    { |j| "MON#{j}" },
            'osds'         => (0...numberOf["OSDs"][:value]).map    { |j| "OSD#{j}" },
            'mdss'         => (0...numberOf["MDSs"][:value]).map    { |j| "MDS#{j}" },
            'rgws'         => (0...numberOf["RGWs"][:value]).map    { |j| "RGW#{j}" },
            'clients'      => (0...numberOf["clients"][:value]).map { |j| "Client#{j}" }
          }
          # Ugly but necessay: https://github.com/mitchellh/vagrant/issues/6726
          ansible.raw_arguments = [
            "--extra-vars",
            "'osd_auto_discovery=true journal_collocation=true journal_size=1024 ceph_rhcs=true ceph_rhcs_version=2 ceph_rhcs_cdn_install=true cluster_network=\"#{SUBNET}0/24\" public_network=\"#{SUBNET}0/24\" monitor_interface=\"eth1\"'"
          ]
        end # end provision
      end #end if

    end # end config

  end #end cluster

  # The flow is outside->in so that this will run before all node specific Shell skripts mentioned above!
  config.vm.provision "shell", inline: <<-SHELL
    echo '#{hostsFile}' | sudo tee -a /etc/hosts
    echo 'Host *' | sudo tee -a /root/.ssh/config
    echo ' StrictHostKeyChecking no' | sudo tee -a /root/.ssh/config
    echo ' UserKnownHostsFile=/dev/null' | sudo tee -a /root/.ssh/config
    echo 'vagrant' | passwd --stdin vagrant
    ifdown eth1; ifup eth1 # Hotfix weird ip address glitch in libvirt
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
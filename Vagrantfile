# -*- mode: ruby -*-
# vi: set ft=ruby :

$install_puppet = <<-PUPPET
sudo apt update -y
sudo apt install -y puppet
PUPPET

Vagrant.configure("2") do |config|
  
  config.vm.provider :libvirt do |lv|
    lv.cpus = 1
    lv.memory = 1024
  end

  config.vm.synced_folder ".", "/vagrant",
    type: "nfs",
    nfs_version: 4,
    nfs_udp: false

  config.vm.synced_folder "/home/bastian/Documents/2026-1S/CONU/vms/shared", "/shared",
    type: "nfs", 
    nfs_version: 4,
    nfs_udp: false

  config.vm.define :servidor do |servidor|
    servidor.vm.box = "generic/ubuntu2204"
    servidor.vm.network :private_network, ip: "192.168.100.3"
    servidor.vm.hostname = "servidor"

    servidor.vm.synced_folder "puppet/manifests", "/tmp/vagrant-puppet/manifests",
      type: "rsync"

    servidor.vm.synced_folder "puppet/modules", "/tmp/vagrant-puppet/modules",
      type: "rsync"

    servidor.vm.synced_folder "puppet/cookbooks", "/tmp/vagrant-chef/cookbooks",
      type: "rsync"

    # config.vm.provision "shell", path: "docker_provision.sh"
    servidor.vm.provision "shell", path: "script.sh"
    servidor.vm.provision "shell", inline: $install_puppet
    servidor.vm.provision "shell", path: "script_jupyter.sh"
    servidor.vm.provision :puppet do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "site.pp"
      puppet.module_path    = "puppet/modules"
      puppet.synced_folder_type = "rsync"
    end
    servidor.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "puppet/cookbooks"
      chef.add_recipe "nginx"
      chef.synced_folder_type = "rsync"
      chef.arguments = "--chef-license accept"
    end
  end

  config.vm.define :cliente do |cliente|
    cliente.vm.box = "generic/ubuntu2204"
    cliente.vm.network :private_network, ip: "192.168.100.2"
    cliente.vm.hostname = "cliente"
  end
end

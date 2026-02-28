# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

    config.vm.provider :libvirt do |lv|
    lv.cpus = 1
    lv.memory = 1024
  end

  config.vm.define :servidorWeb do |servidorWeb|
    # Config Inicial
    servidorWeb.vm.box = "generic/ubuntu2204"
    servidorWeb.vm.network :private_network, ip: "192.168.80.3"
    servidorWeb.vm.hostname = "servidorWeb"
    # Shared folder
    servidorWeb.vm.synced_folder "./webApp", "/home/vagrant/webApp",
                          type: "nfs", 
                          nfs_version: 4, 
                          nfs_udp: false
    
    # Provision
    servidorWeb.vm.provision "shell", path: "provision.sh"
  end
end

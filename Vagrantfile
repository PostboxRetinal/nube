# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.provider :libvirt do |lv|
    lv.cpus = 2
    lv.memory = 3072
  end
  
  config.vm.synced_folder ".", "/vagrant", 
                          type: "nfs", 
                          nfs_version: 4, 
                          nfs_udp: false

  config.vm.synced_folder "/home/bastian/Documents/2026-1S/CONU/vms/shared", "/shared",
                          type: "nfs", 
                          nfs_version: 4,
                          nfs_udp: false

  config.vm.provision "shell", path: "provision.sh"

  config.vm.define :servidor do |servidor|
    servidor.vm.box = "generic/ubuntu2204"
    servidor.vm.network :private_network, ip: "192.168.100.3"
    servidor.vm.hostname = "servidor"
  end

  config.vm.define :cliente do |cliente|
    cliente.vm.box = "generic/ubuntu2204"
    cliente.vm.network :private_network, ip: "192.168.100.2"
    cliente.vm.hostname = "cliente"
  end
end
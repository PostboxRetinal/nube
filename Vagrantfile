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

  config.vm.define :server_kubernetes do |server_kubernetes|
    server_kubernetes.vm.box = "generic/ubuntu2204"
    server_kubernetes.vm.network :private_network, ip: "192.168.100.3"
    server_kubernetes.vm.hostname = "serverKubernetes"

    config.vm.provision "shell", path: "../../shared/nube/docker_provision.sh"
    config.vm.provision "shell", path: "../../shared/nube/provision.sh"
  end
end
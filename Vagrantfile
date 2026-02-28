# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :servidorWeb do |servidorWeb|
    # Config Inicial
    servidorWeb.vm.box = "generic/ubuntu2204"
    servidorWeb.vm.network :private_network, ip: "192.168.80.3"
    servidorWeb.vm.hostname = "servidorWeb"
    servidorWeb.vm.synced_folder "./data", "/shared"
    
    # API REST
    servidorWeb.vm.provision "file", source: "frontend", destination: "/home/vagrant/webApp/frontend"
    servidorWeb.vm.provision "file", source: "microUsers", destination: "/home/vagrant/webApp/microUsers"
    servidorWeb.vm.provision "file", source: "microProducts", destination: "/home/vagrant/webApp/microProducts"
    servidorWeb.vm.provision "file", source: "microOrders", destination: "/home/vagrant/webApp/microOrders"
    servidorWeb.vm.provision "file", source: "init.sql", destination: "/home/vagrant/webApp/init.sql"
 
    # Provision
    servidorWeb.vm.provision "shell", path: "provision.sh"
  end
end

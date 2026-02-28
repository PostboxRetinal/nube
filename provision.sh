#!/bin/bash
# provision.sh - Docker, MySQL, and Python/Flask environment setup

set -e

echo "Starting provisioning..."

# Update package index and install prerequisites
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg debconf-utils

echo "Installing Docker..."
# Set up Docker's official GPG key and repository
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
fi

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Manage Docker as a non-root user (vagrant)
getent group docker || sudo groupadd docker
sudo usermod -aG docker vagrant

sudo systemctl enable --now docker.service
sudo systemctl enable --now containerd.service

# Verify Docker installation
if ! sudo systemctl is-active --quiet docker; then
  echo "Error: Docker failed to start." >&2
  exit 1
fi

echo "Installing MySQL..."
# Preconfigure MySQL root password for unattended installation
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

sudo apt-get install mysql-server -y
sudo systemctl start mysql.service

# NOTE: Ensure init.sql is synced to /home/vagrant/ before this step
sudo mysql -h localhost -u root -proot < /home/vagrant/init.sql

# Enable remote access to MySQL
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql.service

echo "Installing Python and Flask ecosystem..."
sudo apt-get install -y python3-dev default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip

# SE ELIMINÓ --break-system-packages YA QUE UBUNTU 22.04 NO LO REQUIERE NI SOPORTA
pip3 install Flask flask-cors Flask-MySQLdb Flask-SQLAlchemy

echo "Provisioning completed successfully."
#!/bin/bash
# provision.sh - minikube provisioning script

set -e
export DEBIAN_FRONTEND=noninteractive

echo "Starting minikube + kubectl provisioning script..."

sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg
echo "Installing minikube"

curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
echo "Minikube installed successfully :)"

echo "Installing kubectl..."
echo "1) Downloading kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

echo "2) Verifying kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

echo "3) Adding gpg-sign and kubernetes apt repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --batch --yes --no-tty --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg >/dev/null
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

echo "4) Installing kubectl..."
sudo apt update
sudo apt install -y kubectl

echo "5) Cleaning up..."
sudo apt autoremove -y

echo "kubectl installed successfully :)"
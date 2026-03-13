#!/bin/bash
# provision.sh - Docker Installation for Ubuntu (Latest LTS)

set -e

echo "Starting Docker installation..."

# 1. Update package index and install prerequisites
apt-get update -y
apt-get install -y ca-certificates curl gnupg

# 2. Set up Docker's official GPG key (Idempotent check)
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

# 3. Add the repository to Apt sources
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y
fi

# 4. Install Docker Engine, CLI, and Compose
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Manage Docker as a non-root user (vagrant)
getent group docker || groupadd docker
usermod -aG docker vagrant

# 6. Configure systemd to start Docker on boot
systemctl enable --now docker.service
systemctl enable --now containerd.service

# 7. Verification
echo "Verifying installation..."
if systemctl is-active --quiet docker; then
  echo "Docker service is running."
  docker --version
else
  echo "Docker failed to start." >&2
  exit 1
fi

echo "Docker provisioning complete."
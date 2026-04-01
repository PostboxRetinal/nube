#!/bin/bash
# =============================================================================
# Install Essential Packages
# =============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
PROVIDER="${INFRA_PROVIDER:-libvirt}"

echo "============================================"
echo "Installing Essential Packages"
echo "============================================"

# Update package lists
echo "Updating package lists..."
apt-get update -qq

# Install essential packages
echo "Installing essential packages..."
apt-get install -y -qq \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    git \
    unzip \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    sshpass \
    net-tools \
    iputils-ping \
    dnsutils \
    vim \
    htop

# VirtualBox provider requires VBoxManage available where Terraform runs.
if [[ "${PROVIDER}" == "virtualbox" ]]; then
    echo "Installing VirtualBox packages for nested VM provisioning..."
    apt-get install -y -qq virtualbox virtualbox-dkms

    # Ensure the vagrant user can access VirtualBox management commands.
    usermod -aG vboxusers vagrant || true

    echo "Validating VBoxManage..."
    if command -v VBoxManage >/dev/null 2>&1; then
        VBoxManage --version
    else
        echo "ERROR: VBoxManage not found after installation"
        exit 1
    fi
fi

echo "============================================"
echo "Essential Packages Installed"
echo "============================================"
#!/bin/bash
# =============================================================================
# Install Essential Packages
# =============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

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

echo "============================================"
echo "Essential Packages Installed"
echo "============================================"
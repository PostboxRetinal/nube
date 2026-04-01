#!/bin/bash
# =============================================================================
# Install Ansible
# =============================================================================

set -euo pipefail

echo "============================================"
echo "Installing Ansible"
echo "============================================"

# Check if Ansible is already installed
if command -v ansible &> /dev/null; then
    echo "Ansible already installed:"
    ansible --version | head -1
    exit 0
fi

echo "Installing Ansible via pip..."

# Upgrade pip
pip3 install --quiet --upgrade pip

# Install Ansible and related tools
pip3 install --quiet \
    ansible \
    ansible-lint \
    jmespath

# Verify installation
echo "Verifying Ansible installation..."
ansible --version

echo "============================================"
echo "Ansible Installation Complete"
echo "============================================"
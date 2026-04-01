#!/bin/bash
# =============================================================================
# Install Terraform
# =============================================================================

set -euo pipefail

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.7.0}"

echo "============================================"
echo "Installing Terraform"
echo "============================================"

# Check if Terraform is already installed
if command -v terraform &> /dev/null; then
    INSTALLED_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "Terraform already installed: v${INSTALLED_VERSION}"
    exit 0
fi

echo "Installing Terraform ${TERRAFORM_VERSION}..."

# Add HashiCorp GPG key
wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
apt-get update -qq
apt-get install -y -qq terraform

# Verify installation
echo "Verifying Terraform installation..."
terraform version

echo "============================================"
echo "Terraform Installation Complete"
echo "============================================"
#!/bin/bash
# =============================================================================
# Setup Terraform Providers
# =============================================================================

set -euo pipefail

PROVIDER="${INFRA_PROVIDER:-libvirt}"

echo "============================================"
echo "Setting Up Terraform for Provider: ${PROVIDER}"
echo "============================================"

# Create Terraform plugin cache directory
mkdir -p "${HOME}/.terraform.d/plugin-cache"

# Create Terraform CLI configuration
cat > "${HOME}/.terraformrc" << 'EOF'
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true
EOF

# Set environment variable for provider
echo "export INFRA_PROVIDER=${PROVIDER}" >> "${HOME}/.bashrc"

# Create provider-specific environment file
sudo mkdir -p /etc/environment.d
echo "INFRA_PROVIDER=${PROVIDER}" | sudo tee /etc/environment.d/infra-provider.conf

echo "Terraform provider configuration:"
echo "  Provider: ${PROVIDER}"
echo "  Plugin cache: ${HOME}/.terraform.d/plugin-cache"
echo "  Config file: ${HOME}/.terraformrc"

echo "============================================"
echo "Terraform Provider Setup Complete"
echo "============================================"
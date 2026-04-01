#!/bin/bash
# =============================================================================
# Generate SSH Keys for Infrastructure Automation
# =============================================================================

set -euo pipefail

SSH_KEY_PATH="${HOME}/.ssh/infra_key"
SSH_KEYS_SHARED="/home/vagrant/ssh-keys"

echo "============================================"
echo "Generating SSH Keys"
echo "============================================"

# Create .ssh directory if it doesn't exist
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Generate SSH key pair if it doesn't exist
if [[ ! -f "${SSH_KEY_PATH}" ]]; then
    echo "Generating new SSH key pair..."
    ssh-keygen -t ed25519 -f "${SSH_KEY_PATH}" -N "" -C "infrastructure-automation"
    chmod 600 "${SSH_KEY_PATH}"
    chmod 644 "${SSH_KEY_PATH}.pub"
    echo "SSH key pair generated successfully"
else
    echo "SSH key pair already exists"
fi

# Copy keys to shared location if directory exists
if [[ -d "${SSH_KEYS_SHARED}" ]]; then
    echo "Copying SSH keys to shared location..."
    cp "${SSH_KEY_PATH}" "${SSH_KEYS_SHARED}/infra_key"
    cp "${SSH_KEY_PATH}.pub" "${SSH_KEYS_SHARED}/infra_key.pub"
    chmod 600 "${SSH_KEYS_SHARED}/infra_key"
    chmod 644 "${SSH_KEYS_SHARED}/infra_key.pub"
fi

echo "SSH key fingerprint:"
ssh-keygen -lf "${SSH_KEY_PATH}.pub"

echo "============================================"
echo "SSH Keys Generation Complete"
echo "============================================"
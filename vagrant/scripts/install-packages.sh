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
    socat \
    net-tools \
    iputils-ping \
    dnsutils \
    vim \
    genisoimage \
    apparmor-utils

# KVM/Libvirt provider requires libvirt and qemu packages.
if [[ "${PROVIDER}" == "libvirt" ]]; then
    echo "Installing Libvirt/KVM packages for nested VM provisioning..."

    libvirt_install_ok=0
    for attempt in 1 2 3; do
        echo "Libvirt install attempt ${attempt}/3..."
        apt-get update -qq || true
        if apt-get install -y -qq --fix-missing libvirt-daemon-system libvirt-clients qemu-kvm; then
            libvirt_install_ok=1
            break
        fi
        sleep 5
    done

    if [[ "${libvirt_install_ok}" -ne 1 ]]; then
        echo "ERROR: Could not install libvirt packages after 3 attempts"
        exit 1
    fi

    # Ensure the vagrant user can access libvirt management.
    usermod -aG libvirt vagrant || true

    echo "Enabling and starting libvirt service..."
    systemctl enable --now libvirtd
    if ! systemctl is-active --quiet libvirtd; then
        echo "ERROR: libvirtd service is not active"
        systemctl status libvirtd --no-pager
        exit 1
    fi

    echo "Validating virsh..."
    if command -v virsh >/dev/null 2>&1; then
        virsh --version
    else
        echo "ERROR: virsh not found after installation"
        exit 1
    fi

    # Fix libvirt image permissions for qemu/kvm access.
    LIBVIRT_IMAGE_DIR="/var/lib/libvirt/images"
    if [[ -d "${LIBVIRT_IMAGE_DIR}" ]]; then
        echo "Setting ownership and mode for ${LIBVIRT_IMAGE_DIR}..."
        chown -R libvirt-qemu:kvm "${LIBVIRT_IMAGE_DIR}" || chown -R qemu:qemu "${LIBVIRT_IMAGE_DIR}" || true
        find "${LIBVIRT_IMAGE_DIR}" -type d -exec chmod 0755 {} +
        find "${LIBVIRT_IMAGE_DIR}" -type f -exec chmod 0644 {} +
        if command -v restorecon >/dev/null 2>&1; then
            restorecon -Rv "${LIBVIRT_IMAGE_DIR}" || true
        fi
    else
        echo "Warning: ${LIBVIRT_IMAGE_DIR} does not exist yet; will validate later." 
    fi
fi

# VirtualBox provider requires VBoxManage available where Terraform runs.
if [[ "${PROVIDER}" == "virtualbox" ]]; then
    echo "Installing VirtualBox packages for nested VM provisioning..."
    vbox_install_ok=0
    for attempt in 1 2 3; do
        echo "VirtualBox install attempt ${attempt}/3..."
        apt-get update -qq || true
        if apt-get install -y -qq --fix-missing virtualbox virtualbox-dkms; then
            vbox_install_ok=1
            break
        fi
        sleep 5
    done

    if [[ "${vbox_install_ok}" -ne 1 ]]; then
        echo "ERROR: Could not install VirtualBox packages after 3 attempts"
        exit 1
    fi

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

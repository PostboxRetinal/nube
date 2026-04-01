#!/bin/bash
# =============================================================================
# Create Helper Scripts
# =============================================================================

set -euo pipefail

PROVIDER="${INFRA_PROVIDER:-libvirt}"
CONTROL_IP="${CONTROL_NODE_IP:-192.168.57.10}"

echo "============================================"
echo "Creating Helper Scripts"
echo "============================================"

# Create infrastructure deployment script
cat > "${HOME}/deploy-infrastructure.sh" << SCRIPT
#!/bin/bash
set -e

PROVIDER="\${INFRA_PROVIDER:-${PROVIDER}}"

# Map provider names for terraform directory
if [[ "\${PROVIDER}" == "libvirt" ]]; then
    TERRAFORM_DIR="/home/vagrant/terraform/kvm-libvirt"
else
    TERRAFORM_DIR="/home/vagrant/terraform/\${PROVIDER}"
fi

echo "============================================"
echo "Deploying Infrastructure"
echo "Provider: \${PROVIDER}"
echo "Terraform Directory: \${TERRAFORM_DIR}"
echo "============================================"

cd "\${TERRAFORM_DIR}"

if [[ "\${PROVIDER}" == "virtualbox" ]]; then
    echo ""
    echo ">>> Validating VirtualBox host-only network..."

    VBOX_GA_BOX_URL="\${VBOX_GA_BOX_URL:-https://vagrantcloud.com/generic/boxes/ubuntu2204/versions/4.3.12/providers/virtualbox.box}"
    CACHE_DIR="\${HOME}/.cache/tf-virtualbox"
    BOX_FILE="\${CACHE_DIR}/generic-ubuntu2204-virtualbox.box"
    TF_VM_IMAGE="\${BOX_FILE}"

    mkdir -p "\${CACHE_DIR}"

    if [[ ! -f "\${BOX_FILE}" ]]; then
        echo "Downloading Guest Additions base image (generic/ubuntu2204)..."
        wget -q -O "\${BOX_FILE}" "\${VBOX_GA_BOX_URL}"
    fi

    if [[ -z "\${TF_VM_IMAGE}" ]]; then
        echo "ERROR: Could not prepare VirtualBox base image file."
        exit 1
    fi

    HOSTONLY_IFACE="\$(VBoxManage list hostonlyifs | awk -F: '/^Name:/ {gsub(/^[ \t]+/, "", \$2); print \$2; exit}')"

    if [[ -z "\${HOSTONLY_IFACE}" ]]; then
        CREATE_OUTPUT="\$(VBoxManage hostonlyif create)"
        HOSTONLY_IFACE="\$(echo "\${CREATE_OUTPUT}" | sed -n "s/.*'\([^']*\)'.*/\1/p")"
    fi

    if [[ -z "\${HOSTONLY_IFACE}" ]]; then
        echo "ERROR: Could not determine/create a host-only interface for VirtualBox."
        exit 1
    fi

    VBoxManage hostonlyif ipconfig "\${HOSTONLY_IFACE}" --ip 192.168.56.1 --netmask 255.255.255.0
    echo "Using host-only interface: \${HOSTONLY_IFACE}"
    echo "Using VM base image: \${TF_VM_IMAGE}"
fi

echo ""
echo ">>> Initializing Terraform..."
terraform init

echo ""
echo ">>> Planning infrastructure..."
if [[ "\${PROVIDER}" == "virtualbox" ]]; then
    terraform plan \
    -var "vm_image=\${TF_VM_IMAGE}" \
      -var "network_name=\${HOSTONLY_IFACE}" \
      -var "network_gateway=192.168.56.1" \
      -out=tfplan
else
    terraform plan -out=tfplan
fi

echo ""
echo ">>> Applying infrastructure..."
if [[ "\${PROVIDER}" == "virtualbox" ]]; then
    terraform apply -parallelism=1 -auto-approve tfplan
else
    terraform apply -auto-approve tfplan
fi

echo ""
echo "============================================"
echo "Infrastructure Deployment Complete!"
echo "============================================"
terraform output
SCRIPT
chmod +x "${HOME}/deploy-infrastructure.sh"

# Create infrastructure destroy script
cat > "${HOME}/destroy-infrastructure.sh" << SCRIPT
#!/bin/bash
set -e

PROVIDER="\${INFRA_PROVIDER:-${PROVIDER}}"

if [[ "\${PROVIDER}" == "libvirt" ]]; then
    TERRAFORM_DIR="/home/vagrant/terraform/kvm-libvirt"
else
    TERRAFORM_DIR="/home/vagrant/terraform/\${PROVIDER}"
fi

echo "============================================"
echo "Destroying Infrastructure"
echo "Provider: \${PROVIDER}"
echo "============================================"

cd "\${TERRAFORM_DIR}"

echo ""
echo ">>> Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "============================================"
echo "Infrastructure Destroyed!"
echo "============================================"
SCRIPT
chmod +x "${HOME}/destroy-infrastructure.sh"

# Create status check script
cat > "${HOME}/check-status.sh" << SCRIPT
#!/bin/bash

PROVIDER="\${INFRA_PROVIDER:-${PROVIDER}}"

echo "============================================"
echo "Infrastructure Status Check"
echo "Provider: \${PROVIDER}"
echo "============================================"

# Check Terraform state
if [[ "\${PROVIDER}" == "libvirt" ]]; then
    TERRAFORM_DIR="/home/vagrant/terraform/kvm-libvirt"
else
    TERRAFORM_DIR="/home/vagrant/terraform/\${PROVIDER}"
fi

if [[ -f "\${TERRAFORM_DIR}/terraform.tfstate" ]]; then
    echo ""
    echo "Terraform Resources:"
    cd "\${TERRAFORM_DIR}"
    terraform state list 2>/dev/null || echo "  No resources found"
else
    echo ""
    echo "Terraform state not found. Infrastructure may not be deployed."
fi

# Check VM connectivity
echo ""
echo "VM Connectivity:"
for vm in "192.168.56.20:vm-haproxy" "192.168.56.30:vm-microservices"; do
    ip=\${vm%%:*}
    name=\${vm##*:}
    if ping -c 1 -W 2 \${ip} &>/dev/null; then
        echo "  \${name} (\${ip}): REACHABLE"
    else
        echo "  \${name} (\${ip}): UNREACHABLE"
    fi
done

# Test HAProxy
echo ""
echo "HAProxy Status:"
http_code=\$(curl -s -o /dev/null -w "%{http_code}" http://192.168.56.20:80 2>/dev/null || echo "000")
if [[ "\${http_code}" != "000" ]]; then
    echo "  Port 80: LISTENING (HTTP \${http_code})"
else
    echo "  Port 80: NOT RESPONDING"
fi

stats_code=\$(curl -s -o /dev/null -w "%{http_code}" http://192.168.56.20:8080/stats 2>/dev/null || echo "000")
if [[ "\${stats_code}" != "000" ]]; then
    echo "  Port 8080 (Stats): LISTENING (HTTP \${stats_code})"
else
    echo "  Port 8080 (Stats): NOT RESPONDING"
fi

echo ""
echo "============================================"
SCRIPT
chmod +x "${HOME}/check-status.sh"

# Create test endpoints script
cat > "${HOME}/test-endpoints.sh" << SCRIPT
#!/bin/bash

HAPROXY_IP="192.168.56.20"

echo "============================================"
echo "Testing HAProxy Endpoints"
echo "============================================"

echo ""
echo ">>> Testing /api/users/"
curl -s -w "\\nHTTP Status: %{http_code}\\n" "http://\${HAPROXY_IP}/api/users/" || echo "Failed to connect"

echo ""
echo ">>> Testing /api/products/"
curl -s -w "\\nHTTP Status: %{http_code}\\n" "http://\${HAPROXY_IP}/api/products/" || echo "Failed to connect"

echo ""
echo ">>> Testing /api/orders/"
curl -s -w "\\nHTTP Status: %{http_code}\\n" "http://\${HAPROXY_IP}/api/orders/" || echo "Failed to connect"

echo ""
echo ">>> HAProxy Stats (use admin:haproxy_admin_2024)"
echo "URL: http://\${HAPROXY_IP}:8080/stats"

echo ""
echo "============================================"
SCRIPT
chmod +x "${HOME}/test-endpoints.sh"

echo "Helper scripts created:"
echo "  - deploy-infrastructure.sh"
echo "  - destroy-infrastructure.sh"
echo "  - check-status.sh"
echo "  - test-endpoints.sh"

echo "============================================"
echo "Helper Scripts Created"
echo "============================================"
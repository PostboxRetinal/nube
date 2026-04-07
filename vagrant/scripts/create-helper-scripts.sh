#!/bin/bash
# =============================================================================
# Create Helper Scripts
# =============================================================================

set -euo pipefail

PROVIDER="${INFRA_PROVIDER:-libvirt}"
NETWORK_NAME="${NETWORK_NAME:-infrastructure-net}"
NETWORK_BRIDGE_NAME="${NETWORK_BRIDGE_NAME:-virbr10}"

if [[ "${PROVIDER}" == "libvirt" ]]; then
    DEFAULT_CONTROL_IP="192.168.123.10"
    DEFAULT_HAPROXY_IP="192.168.124.20"
    DEFAULT_MICROSERVICES_IP="192.168.124.30"
else
    DEFAULT_CONTROL_IP="192.168.57.10"
    DEFAULT_HAPROXY_IP="192.168.57.20"
    DEFAULT_MICROSERVICES_IP="192.168.57.30"
fi

CONTROL_IP="${CONTROL_NODE_IP:-${DEFAULT_CONTROL_IP}}"

HAPROXY_IP="${HAPROXY_IP:-${DEFAULT_HAPROXY_IP}}"
MICROSERVICES_IP="${MICROSERVICES_IP:-${DEFAULT_MICROSERVICES_IP}}"
echo "============================================"
echo "Creating Helper Scripts"
echo "============================================"

# QoL: avoid clear/terminal issues when host uses kitty terminfo
if ! grep -q 'export TERM=xterm-256color' "${HOME}/.bashrc" 2>/dev/null; then
    echo 'export TERM=xterm-256color' >> "${HOME}/.bashrc"
fi
export TERM=xterm-256color

# Create infrastructure deployment script
cat > "${HOME}/deploy-infrastructure.sh" << 'SCRIPT'
#!/bin/bash
set -e

PROVIDER="${INFRA_PROVIDER:-libvirt}"
NETWORK_NAME="${NETWORK_NAME:-infrastructure-net}"
NETWORK_BRIDGE_NAME="${NETWORK_BRIDGE_NAME:-virbr10}"

# Map provider names for terraform directory
if [[ "${PROVIDER}" == "libvirt" ]]; then
    TERRAFORM_DIR="/home/vagrant/terraform/kvm-libvirt"
else
    TERRAFORM_DIR="/home/vagrant/terraform/${PROVIDER}"
fi

echo "============================================"
echo "Deploying Infrastructure"
echo "Provider: ${PROVIDER}"
echo "Terraform Directory: ${TERRAFORM_DIR}"
echo "============================================"

cd "${TERRAFORM_DIR}"

if [[ "${PROVIDER}" == "libvirt" ]]; then
    echo ""
    echo ">>> Validating libvirt service..."
    if ! systemctl is-active --quiet libvirtd; then
        echo ">>> libvirtd is not active; trying to start it..."
        sudo systemctl enable --now libvirtd
    fi
    if ! systemctl is-active --quiet libvirtd; then
        echo "ERROR: libvirtd service is not active; cannot proceed with Terraform libvirt provider."
        systemctl status libvirtd --no-pager || true
        exit 1
    fi

    echo ">>> Applying nested-libvirt qemu access hardening..."
    QEMU_CONF="/etc/libvirt/qemu.conf"
    LIBVIRT_RESTART_REQUIRED=0

    set_qemu_conf_value() {
        local key="$1"
        local value="$2"
        local escaped_value
        escaped_value="$(printf '%s' "${value}" | sed 's/[&/]/\\&/g')"

        if sudo grep -Eq "^[#[:space:]]*${key}[[:space:]]*=" "${QEMU_CONF}"; then
            current_value="$(sudo awk -F'= *' -v k="${key}" '$0 ~ "^[#[:space:]]*"k"[[:space:]]*=" {print $2; exit}' "${QEMU_CONF}" | xargs || true)"
            if [[ "${current_value}" != "${value}" ]]; then
                sudo sed -i -E "s|^[#[:space:]]*${key}[[:space:]]*=.*|${key} = ${escaped_value}|" "${QEMU_CONF}"
                LIBVIRT_RESTART_REQUIRED=1
            fi
        else
            echo "${key} = ${value}" | sudo tee -a "${QEMU_CONF}" >/dev/null
            LIBVIRT_RESTART_REQUIRED=1
        fi
    }

    set_qemu_conf_value "user" '"root"'
    set_qemu_conf_value "group" '"root"'
    set_qemu_conf_value "dynamic_ownership" "0"
    set_qemu_conf_value "security_driver" '"none"'

    if [[ "${LIBVIRT_RESTART_REQUIRED}" -eq 1 ]]; then
        echo ">>> Restarting libvirtd to apply qemu.conf changes..."
        sudo systemctl restart libvirtd
    fi

    VIRSH_CMD="sudo virsh -c qemu:///system"

    validate_network_drift() {
        local expected_bridge="$1"
        local net_xml current_bridge current_mode

        if ! ${VIRSH_CMD} net-list --all | awk '{print $1}' | grep -q "^${NETWORK_NAME}$"; then
            return 0
        fi

        net_xml="$(${VIRSH_CMD} net-dumpxml "${NETWORK_NAME}" 2>/dev/null || true)"
        current_bridge="$(printf '%s\n' "${net_xml}" | sed -n "s/.*<bridge name='\\([^']*\\)'.*/\\1/p" | head -n1)"
        current_mode="$(printf '%s\n' "${net_xml}" | sed -n "s/.*<forward mode='\\([^']*\\)'.*/\\1/p" | head -n1)"

        if [[ -z "${current_mode}" ]]; then
            current_mode="isolated"
        fi

        if [[ "${current_mode}" != "nat" ]]; then
            echo "ERROR: Drift detected for libvirt network '${NETWORK_NAME}'."
            echo "  Expected forward mode: nat"
            echo "  Current forward mode: ${current_mode}"
            echo "Refusing to continue to avoid inconsistent behavior."
            echo "Fix by redefining '${NETWORK_NAME}' with NAT mode, then rerun deployment."
            return 1
        fi

        if [[ -n "${current_bridge}" && "${current_bridge}" != "${expected_bridge}" ]]; then
            echo "ERROR: Drift detected for libvirt network '${NETWORK_NAME}'."
            echo "  Expected bridge: ${expected_bridge}"
            echo "  Current bridge:  ${current_bridge}"

            if [[ "${current_bridge}" =~ ^(eth|enp|ens|eno|wlan|wlp)[a-zA-Z0-9._:-]*$ ]]; then
                echo "  '${current_bridge}' looks like a host interface, which can trigger collisions like:"
                echo "  'Network is already in use by interface ${current_bridge}'."
            fi

            echo "Refusing to continue to avoid apply-time failures."
            echo "Remediation:"
            echo "  1) terraform destroy (if state exists), or"
            echo "  2) sudo virsh -c qemu:///system net-destroy '${NETWORK_NAME}' && sudo virsh -c qemu:///system net-undefine '${NETWORK_NAME}'"
            echo "  3) rerun deployment so Terraform recreates the network with bridge '${expected_bridge}'."
            return 1
        fi
    }

    ensure_pool_active() {
        local pool_name="$1"
        local pool_state
        pool_state="$(${VIRSH_CMD} pool-info "${pool_name}" 2>/dev/null | awk -F': *' '/^State/ {print $2}' || true)"

        ${VIRSH_CMD} pool-autostart "${pool_name}" || true
        if [[ "${pool_state}" != "running" ]]; then
            ${VIRSH_CMD} pool-start "${pool_name}" || true
        fi
    }

    echo ">>> Validating libvirt storage pool 'default'..."
    if ! ${VIRSH_CMD} pool-list --all | awk '{print $1}' | grep -q "^default$"; then
        echo ">>> Defining libvirt pool 'default'..."
        if ! ${VIRSH_CMD} pool-define-as default dir --target /var/lib/libvirt/images; then
            echo ">>> libvirt pool 'default' already defined or failed. Continuing."
        fi
        ensure_pool_active default
    else
        echo ">>> libvirt pool 'default' already exists; ensuring running"
        ensure_pool_active default
    fi

    echo ">>> Validating libvirt network '${NETWORK_NAME}'..."
    if ${VIRSH_CMD} net-list --all | awk '{print $1}' | grep -q "^${NETWORK_NAME}$"; then
        echo ">>> Network '${NETWORK_NAME}' already defined; skipping creation."
    else
        echo ">>> Network '${NETWORK_NAME}' not found; creating now ..."
        # create network only if not existing; Terraform will own it if provided in network.tf
    fi

    echo ">>> Running libvirt network drift preflight..."
    validate_network_drift "${NETWORK_BRIDGE_NAME}"

    cleanup_existing_domains() {
        local domains_to_remove=()
        for domain in vm-haproxy vm-microservices; do
            if sudo virsh -c qemu:///system domstate "${domain}" >/dev/null 2>&1; then
                domains_to_remove+=("${domain}")
            fi
        done

        if [[ ":${domains_to_remove[*]}:" != ":" ]]; then
            echo "Detected existing libvirt domains: ${domains_to_remove[*]}"
            for domain in "${domains_to_remove[@]}"; do
                echo "Destroying and undefining existing domain (preserving disks): ${domain}"
                sudo virsh -c qemu:///system destroy "${domain}" >/dev/null 2>&1 || true
                sudo virsh -c qemu:///system undefine "${domain}" >/dev/null 2>&1 || true
            done
            echo "Cleaned existing domains."
        fi
    }

    echo ">>> Cleaning any stale libvirt domains before planning..."
    cleanup_existing_domains
fi

if [[ "${PROVIDER}" == "virtualbox" ]]; then
    echo ""
    echo ">>> Validating VirtualBox host-only network..."

    VBOX_GA_BOX_URL="${VBOX_GA_BOX_URL:-https://vagrantcloud.com/generic/boxes/ubuntu2204/versions/4.3.12/providers/virtualbox.box}"
    CACHE_DIR="${HOME}/.cache/tf-virtualbox"
    BOX_FILE="${CACHE_DIR}/generic-ubuntu2204-virtualbox.box"
    TF_VM_IMAGE="${BOX_FILE}"

    mkdir -p "${CACHE_DIR}"

    if [[ ! -f "${BOX_FILE}" ]]; then
        echo "Downloading Guest Additions base image (generic/ubuntu2204)..."
        wget -q -O "${BOX_FILE}" "${VBOX_GA_BOX_URL}"
    fi

    if [[ -z "${TF_VM_IMAGE}" ]]; then
        echo "ERROR: Could not prepare VirtualBox base image file."
        exit 1
    fi

    HOSTONLY_IFACE="$(VBoxManage list hostonlyifs | awk -F: '/^Name:/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')"

    if [[ -z "${HOSTONLY_IFACE}" ]]; then
        CREATE_OUTPUT="$(VBoxManage hostonlyif create)"
        HOSTONLY_IFACE="$(echo "${CREATE_OUTPUT}" | awk -F"'" '{print $2}')"
    fi

    if [[ -z "${HOSTONLY_IFACE}" ]]; then
        echo "ERROR: Could not determine/create a host-only interface for VirtualBox."
        exit 1
    fi

    VBoxManage hostonlyif ipconfig "${HOSTONLY_IFACE}" --ip 192.168.57.1 --netmask 255.255.255.0
    echo "Using host-only interface: ${HOSTONLY_IFACE}"
    echo "Using VM base image: ${TF_VM_IMAGE}"
fi

echo ""
echo ">>> Initializing Terraform..."
terraform init

echo ""
echo ">>> Planning infrastructure..."
if [[ "${PROVIDER}" == "virtualbox" ]]; then
    terraform plan \
        -var "vm_image=${TF_VM_IMAGE}" \
            -var "network_name=${HOSTONLY_IFACE}" \
      -var "network_gateway=192.168.57.1" \
      -out=tfplan
else
    terraform plan \
      -var "network_name=${NETWORK_NAME}" \
      -var "network_bridge_name=${NETWORK_BRIDGE_NAME}" \
      -out=tfplan
fi

echo ""
echo ">>> Applying infrastructure..."

# Guard against duplicate domain creation for libvirt.
# If domains already exist, undefine them and continue.
if [[ "${PROVIDER}" == "libvirt" ]]; then
    cleanup_existing_domains
    echo "Continuing terraform apply."
fi

if [[ "${PROVIDER}" == "virtualbox" ]]; then
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
HAPROXY_IP="\${HAPROXY_IP:-${HAPROXY_IP}}"
MICROSERVICES_IP="\${MICROSERVICES_IP:-${MICROSERVICES_IP}}"
HAPROXY_STATS_USER="\${HAPROXY_STATS_USER:-admin}"
HAPROXY_STATS_PASSWORD="\${HAPROXY_STATS_PASSWORD:-haproxy_admin_2024}"

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
for vm in "\${HAPROXY_IP}:vm-haproxy" "\${MICROSERVICES_IP}:vm-microservices"; do
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
http_code=\$(curl -s -o /dev/null -w "%{http_code}" "http://\${HAPROXY_IP}:80" 2>/dev/null || echo "000")
if [[ "\${http_code}" != "000" ]]; then
    echo "  Port 80: LISTENING (HTTP \${http_code})"
else
    echo "  Port 80: NOT RESPONDING"
fi

stats_code=\$(curl -s -o /dev/null -w "%{http_code}" "http://\${HAPROXY_IP}:8080/stats" 2>/dev/null || echo "000")
if [[ "\${stats_code}" != "000" ]]; then
    echo "  Port 8080 (Stats): LISTENING (HTTP \${stats_code})"
else
    echo "  Port 8080 (Stats): NOT RESPONDING"
fi

stats_auth_code=\$(curl -s -u "\${HAPROXY_STATS_USER}:\${HAPROXY_STATS_PASSWORD}" -o /dev/null -w "%{http_code}" "http://\${HAPROXY_IP}:8080/stats" 2>/dev/null || echo "000")
if [[ "\${stats_auth_code}" == "200" ]]; then
    echo "  Stats auth: OK"
else
    echo "  Stats auth: FAILED (HTTP \${stats_auth_code})"
fi

echo ""
echo "============================================"
SCRIPT
chmod +x "${HOME}/check-status.sh"

# Create test endpoints script
cat > "${HOME}/test-endpoints.sh" << SCRIPT
#!/bin/bash

HAPROXY_IP="\${HAPROXY_IP:-${HAPROXY_IP}}"

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

# Create round-robin validation script
cat > "${HOME}/test-roundrobin.sh" << SCRIPT
#!/bin/bash
set -euo pipefail

HAPROXY_IP="\${HAPROXY_IP:-${HAPROXY_IP}}"
REQUESTS="\${REQUESTS:-12}"

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for this test."
    exit 1
fi

echo "============================================"
echo "Testing HAProxy Round-Robin Distribution"
echo "Target: \${HAPROXY_IP} | Requests per service: \${REQUESTS}"
echo "============================================"

for service in users products orders; do
    echo ""
    echo ">>> /api/\${service}/"

    declare -A hits=()
    for i in \$(seq 1 "\${REQUESTS}"); do
        body=\$(curl -s "http://\${HAPROXY_IP}/api/\${service}/")
        server=\$(echo "\${body}" | jq -r '.server // "unknown"')
        current=\${hits[\$server]:-0}
        hits[\$server]=\$((current + 1))
    done

    uniq_count=0
    for k in "\${!hits[@]}"; do
        uniq_count=\$((uniq_count + 1))
        echo "  \${k}: \${hits[\$k]} requests"
    done

    if [[ "\${uniq_count}" -lt 2 ]]; then
        echo "  RESULT: FAIL (traffic did not reach at least 2 backend instances)"
        exit 1
    else
        echo "  RESULT: PASS"
    fi
done

echo ""
echo "Round-robin test completed successfully."
SCRIPT
chmod +x "${HOME}/test-roundrobin.sh"

# Create failover demonstration script
cat > "${HOME}/test-failover.sh" << SCRIPT
#!/bin/bash
set -euo pipefail

HAPROXY_IP="\${HAPROXY_IP:-${HAPROXY_IP}}"
MICROSERVICES_IP="\${MICROSERVICES_IP:-${MICROSERVICES_IP}}"
SERVICE="\${SERVICE:-users}"
INSTANCE_DOWN="\${INSTANCE_DOWN:-users-service-1}"
RECOVER="\${RECOVER:-true}"
SSH_USER="\${SSH_USER:-vagrant}"
SSH_KEY="\${SSH_KEY:-/home/vagrant/.ssh/infra_key}"
SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if [[ -f "\${SSH_KEY}" ]]; then
    SSH_CMD=(ssh -i "\${SSH_KEY}" \${SSH_OPTS} "\${SSH_USER}@\${MICROSERVICES_IP}")
else
    SSH_CMD=(ssh \${SSH_OPTS} "\${SSH_USER}@\${MICROSERVICES_IP}")
fi

stats_csv() {
    curl -s -u "admin:haproxy_admin_2024" "http://\${HAPROXY_IP}:8080/stats;csv"
}

print_backend_state() {
    local backend_name="\$1"
    echo "\$(stats_csv | awk -F, -v b="\${backend_name}" '\$1==b && \$2!="BACKEND" {print "  " \$2 ": " \$18}')"
}

echo "============================================"
echo "Testing HAProxy Failover"
echo "Service: \${SERVICE} | Stop instance: \${INSTANCE_DOWN}"
echo "============================================"

case "\${SERVICE}" in
  users) backend="users_back"; path="users" ;;
  products) backend="products_back"; path="products" ;;
  orders) backend="orders_back"; path="orders" ;;
  *) echo "Invalid SERVICE. Use users|products|orders"; exit 1 ;;
esac

echo ""
echo ">>> Initial backend states"
print_backend_state "\${backend}"

echo ""
echo ">>> Stopping \${INSTANCE_DOWN} on \${MICROSERVICES_IP}"
"\${SSH_CMD[@]}" "docker stop \${INSTANCE_DOWN}" >/dev/null

echo "Waiting for HAProxy health-check detection..."
for _ in {1..12}; do
    state_line=\$(stats_csv | awk -F, -v b="\${backend}" -v s="\${INSTANCE_DOWN}" '\$1==b && \$2==s {print \$18}')
    if [[ "\${state_line}" == "DOWN" ]]; then
        break
    fi
    sleep 2
done

echo ""
echo ">>> Backend states after failure"
print_backend_state "\${backend}"

echo ""
echo ">>> Verifying service continuity via HAProxy"
for i in {1..6}; do
    code=\$(curl -s -o /dev/null -w "%{http_code}" "http://\${HAPROXY_IP}/api/\${path}/")
    echo "  Request \${i}: HTTP \${code}"
    if [[ "\${code}" != "200" ]]; then
        echo "FAIL: service continuity check failed"
        exit 1
    fi
done

if [[ "\${RECOVER}" == "true" ]]; then
    echo ""
    echo ">>> Recovering \${INSTANCE_DOWN}"
    "\${SSH_CMD[@]}" "docker start \${INSTANCE_DOWN}" >/dev/null

    echo "Waiting for HAProxy to mark instance UP..."
    for _ in {1..15}; do
        state_line=\$(stats_csv | awk -F, -v b="\${backend}" -v s="\${INSTANCE_DOWN}" '\$1==b && \$2==s {print \$18}')
        if [[ "\${state_line}" == "UP" ]]; then
            break
        fi
        sleep 2
    done

    echo ""
    echo ">>> Backend states after recovery"
    print_backend_state "\${backend}"
fi

echo ""
echo "Failover test completed."
SCRIPT
chmod +x "${HOME}/test-failover.sh"

echo "Helper scripts created:"
echo "  - deploy-infrastructure.sh"
echo "  - destroy-infrastructure.sh"
echo "  - check-status.sh"
echo "  - test-endpoints.sh"
echo "  - test-roundrobin.sh"
echo "  - test-failover.sh"

echo "============================================"
echo "Helper Scripts Created"
echo "============================================"
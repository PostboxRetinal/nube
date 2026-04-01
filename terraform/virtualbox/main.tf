# =============================================================================
# Main Configuration - VirtualBox
# =============================================================================

# -----------------------------------------------------------------------------
# Read SSH Public Key
# -----------------------------------------------------------------------------

data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key_path
}

# -----------------------------------------------------------------------------
# Virtual Machines
# -----------------------------------------------------------------------------

resource "virtualbox_vm" "vm" {
  for_each = var.vms

  name   = each.value.hostname
  image  = var.vm_image
  cpus   = each.value.vcpu
  memory = "${each.value.memory} mib"

  network_adapter {
    type           = "hostonly"
    host_interface = var.network_name
  }

  network_adapter {
    type = "nat"
  }
}

# -----------------------------------------------------------------------------
# VM Configuration via SSH
# -----------------------------------------------------------------------------

resource "null_resource" "configure_vm" {
  for_each = var.vms

  depends_on = [virtualbox_vm.vm]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = each.value.ip_address
    timeout  = "10m"
  }

  # Configure static IP address
  provisioner "remote-exec" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S bash -c 'cat > /etc/netplan/01-netcfg.yaml << EOF",
      "network:",
      "  version: 2",
      "  ethernets:",
      "    enp0s3:",
      "      dhcp4: false",
      "      addresses:",
      "        - ${each.value.ip_address}/24",
      "      routes:",
      "        - to: default",
      "          via: ${var.network_gateway}",
      "      nameservers:",
      "        addresses: [8.8.8.8, 8.8.4.4]",
      "    enp0s8:",
      "      dhcp4: true",
      "EOF'",
      "echo '${var.ssh_password}' | sudo -S netplan apply || true"
    ]
  }

  # Add SSH public key
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "echo '${trimspace(data.local_file.ssh_public_key.content)}' >> ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
      "echo 'SSH key added successfully'"
    ]
  }

  # Set hostname
  provisioner "remote-exec" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S hostnamectl set-hostname ${each.value.hostname}",
      "echo '${var.ssh_password}' | sudo -S bash -c 'echo \"127.0.0.1 ${each.value.hostname}\" >> /etc/hosts'"
    ]
  }
}

# -----------------------------------------------------------------------------
# Wait for VMs to be Ready with SSH Key Auth
# -----------------------------------------------------------------------------

resource "null_resource" "wait_for_vm" {
  for_each = var.vms

  depends_on = [null_resource.configure_vm]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ${each.value.hostname} SSH key authentication..."
      
      max_attempts=30
      attempt=0
      
      while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -o BatchMode=yes \
               -i ${var.ssh_private_key_path} \
               ${var.ssh_user}@${each.value.ip_address} 'echo ready' 2>/dev/null; then
          echo "${each.value.hostname} is ready with SSH key auth!"
          exit 0
        fi
        
        echo "Attempt $attempt/$max_attempts: waiting..."
        sleep 5
      done
      
      echo "ERROR: Timeout waiting for ${each.value.hostname}"
      exit 1
    EOT
  }
}

# -----------------------------------------------------------------------------
# Generate Ansible Inventory
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.wait_for_vm]

  content = templatefile("${var.ansible_playbook_path}/templates/inventory.tpl", {
    haproxy_ip             = var.vms.haproxy.ip_address
    microservices_ip       = var.vms.microservices.ip_address
    ssh_private_key        = var.ssh_private_key_path
    ssh_user               = var.ssh_user
    haproxy_stats_port     = var.haproxy_stats_port
    haproxy_stats_user     = var.haproxy_stats_user
    haproxy_stats_password = var.haproxy_stats_password
    microservices          = var.microservices
  })

  filename        = "${var.ansible_playbook_path}/inventory/hosts.yml"
  file_permission = "0644"
}

# -----------------------------------------------------------------------------
# Run Ansible Playbooks
# -----------------------------------------------------------------------------

resource "null_resource" "ansible_provision" {
  depends_on = [
    null_resource.wait_for_vm,
    local_file.ansible_inventory
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    working_dir = var.ansible_playbook_path
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      ANSIBLE_FORCE_COLOR       = "true"
    }
    command = <<-EOT
      echo "============================================"
      echo "Running Ansible Playbooks"
      echo "============================================"
      
      ansible-playbook \
        -i inventory/hosts.yml \
        playbooks/site.yml \
        --private-key=${var.ssh_private_key_path} \
        -v
    EOT
  }
}
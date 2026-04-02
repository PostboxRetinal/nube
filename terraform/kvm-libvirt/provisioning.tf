# =============================================================================
# Provisioning - KVM/Libvirt
# =============================================================================

# -----------------------------------------------------------------------------
# Wait for VMs to be Ready
# -----------------------------------------------------------------------------

resource "null_resource" "wait_for_vm" {
  for_each = var.vms

  depends_on = [libvirt_domain.vm]

  triggers = {
    always_run = timestamp()
    vm_id      = libvirt_domain.vm[each.key].id
    vm_ip      = each.value.ip_address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      echo "Waiting for ${each.value.hostname} (${each.value.ip_address}) to be ready..."
      
      max_attempts=60
      attempt=0
      
      while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -o BatchMode=yes \
               -i ${var.ssh_private_key_path} \
               ${var.ssh_user}@${each.value.ip_address} 'echo ready' 2>/dev/null; then
          echo "${each.value.hostname} is ready!"
          exit 0
        fi
        
        echo "Attempt $attempt/$max_attempts: ${each.value.hostname} not ready, waiting 10s..."
        sleep 10
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
    haproxy_ssh_port       = var.vms.haproxy.ssh_port
    microservices_ip       = var.vms.microservices.ip_address
    microservices_ssh_port = var.vms.microservices.ssh_port
    ssh_private_key        = var.ssh_private_key_path
    ssh_user               = var.ssh_user
    ssh_password           = var.ssh_password
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
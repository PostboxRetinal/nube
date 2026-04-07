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
# Local Values
# -----------------------------------------------------------------------------

locals {
  ssh_forward_ports = {
    haproxy       = 2221
    microservices = 2222
  }
}

# -----------------------------------------------------------------------------
# Virtual Machines (VBoxManage workaround for provider guestproperty issue)
# -----------------------------------------------------------------------------

resource "null_resource" "virtualbox_vm" {
  for_each = var.vms

  triggers = {
    name         = each.value.hostname
    image        = var.vm_image
    cpus         = tostring(each.value.vcpu)
    memory       = tostring(each.value.memory)
    network_name = var.network_name
    ssh_port     = tostring(local.ssh_forward_ports[each.key])
    nic_layout   = "nat1-hostonly2-v1"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module}/scripts/vbox_vm_create.sh '${each.value.hostname}' '${var.vm_image}' '${each.value.vcpu}' '${each.value.memory}' '${var.network_name}' '${local.ssh_forward_ports[each.key]}'"
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module}/scripts/vbox_vm_destroy.sh '${self.triggers.name}'"
  }
}

# -----------------------------------------------------------------------------
# Wait for guest readiness via VirtualBox guestcontrol
# -----------------------------------------------------------------------------

resource "null_resource" "wait_for_ssh" {
  for_each = var.vms

  depends_on = [null_resource.virtualbox_vm]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module}/scripts/wait_guestcontrol.sh '${each.value.hostname}' '${var.ssh_user}' '${var.ssh_password}'"
  }
}

# -----------------------------------------------------------------------------
# VM Configuration via SSH
# -----------------------------------------------------------------------------

resource "null_resource" "configure_vm" {
  for_each = var.vms

  triggers = {
    hostname   = each.value.hostname
    ip_address = each.value.ip_address
    ssh_user   = var.ssh_user
    ssh_port   = tostring(local.ssh_forward_ports[each.key])
  }

  depends_on = [null_resource.wait_for_ssh]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module}/scripts/configure_vm_guestcontrol.sh '${each.value.hostname}' '${var.ssh_user}' '${var.ssh_password}' '${each.value.hostname}' '${each.value.ip_address}' '${base64encode(trimspace(data.local_file.ssh_public_key.content))}'"
  }
}

# -----------------------------------------------------------------------------
# Wait for VMs to be Ready with SSH Key Auth
# -----------------------------------------------------------------------------

resource "null_resource" "wait_for_vm" {
  for_each = var.vms

  triggers = {
    hostname   = each.value.hostname
    ip_address = each.value.ip_address
    ssh_user   = var.ssh_user
    ssh_port   = tostring(local.ssh_forward_ports[each.key])
  }

  depends_on = [null_resource.configure_vm]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module}/scripts/wait_guestcontrol.sh '${each.value.hostname}' '${var.ssh_user}' '${var.ssh_password}'"
  }
}

# -----------------------------------------------------------------------------
# Generate Ansible Inventory
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.wait_for_vm]

  content = templatefile("${var.ansible_playbook_path}/templates/inventory.tpl", {
    network_prefix         = join(".", slice(split(".", split("/", var.network_cidr)[0]), 0, 3))
    control_node_ip        = var.control_node_ip
    haproxy_ip             = var.vms.haproxy.ip_address
    microservices_ip       = var.vms.microservices.ip_address
    haproxy_ssh_port       = local.ssh_forward_ports.haproxy
    microservices_ssh_port = local.ssh_forward_ports.microservices
    haproxy_ansible_host   = "127.0.0.1"
    microservices_ansible_host = "127.0.0.1"
    ssh_password           = var.ssh_password
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
      ANSIBLE_ROLES_PATH        = "${var.ansible_playbook_path}/roles"
    }
    command = "echo '============================================'; echo 'Running Ansible Playbooks'; echo '============================================'; ansible-playbook -i inventory/hosts.yml playbooks/site.yml -v"
  }
}
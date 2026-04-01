# =============================================================================
# Compute Resources - KVM/Libvirt
# =============================================================================

# -----------------------------------------------------------------------------
# Read SSH Public Key
# -----------------------------------------------------------------------------

data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key_path
}

# -----------------------------------------------------------------------------
# Base Image
# -----------------------------------------------------------------------------

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-base.qcow2"
  pool   = var.storage_pool
  source = var.base_image_url
  format = "qcow2"
}

# -----------------------------------------------------------------------------
# VM Disks
# -----------------------------------------------------------------------------

resource "libvirt_volume" "vm_disk" {
  for_each = var.vms

  name           = "${each.value.hostname}-disk.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = each.value.disk_size
  format         = "qcow2"
}

# -----------------------------------------------------------------------------
# Cloud-Init Configuration
# -----------------------------------------------------------------------------

resource "libvirt_cloudinit_disk" "vm_cloudinit" {
  for_each = var.vms

  name = "${each.value.hostname}-cloudinit.iso"
  pool = var.storage_pool

  user_data = templatefile("${path.module}/cloud-init/user-data.tpl", {
    hostname       = each.value.hostname
    ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
    ssh_user       = var.ssh_user
  })

  network_config = templatefile("${path.module}/cloud-init/network-config.tpl", {
    ip_address = each.value.ip_address
    gateway    = var.network_gateway
  })
}

# -----------------------------------------------------------------------------
# Virtual Machines
# -----------------------------------------------------------------------------

resource "libvirt_domain" "vm" {
  for_each = var.vms

  name      = each.value.hostname
  memory    = each.value.memory
  vcpu      = each.value.vcpu
  cloudinit = libvirt_cloudinit_disk.vm_cloudinit[each.key].id
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id     = libvirt_network.infrastructure.id
    hostname       = each.value.hostname
    addresses      = [each.value.ip_address]
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }

  qemu_agent = true
}
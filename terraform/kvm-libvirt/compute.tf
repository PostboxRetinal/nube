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
# VM Disks
# -----------------------------------------------------------------------------

resource "libvirt_volume" "vm_disk" {
  for_each = var.vms

  name           = "${each.value.hostname}-disk.qcow2"
  pool           = var.storage_pool
  source         = var.base_image_url
  format         = "qcow2"
}

resource "null_resource" "resize_vm_disk" {
  for_each = var.vms

  depends_on = [libvirt_volume.vm_disk]

  triggers = {
    always_run = timestamp()
    disk_id    = libvirt_volume.vm_disk[each.key].id
    disk_size  = tostring(each.value.disk_size)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      set -euo pipefail

      DISK_PATH="${libvirt_volume.vm_disk[each.key].id}"
      TARGET_SIZE_BYTES="${each.value.disk_size}"

      RUNTIME_QEMU_USER="$(ps -eo user=,comm= | awk '$2 ~ /^qemu-system/ {print $1; exit}' || true)"
      RUNTIME_QEMU_GROUP="$(ps -eo group=,comm= | awk '$2 ~ /^qemu-system/ {print $1; exit}' || true)"

      QEMU_USER="$${RUNTIME_QEMU_USER}"
      QEMU_GROUP="$${RUNTIME_QEMU_GROUP}"

      if [[ -z "$${QEMU_USER}" ]]; then
        QEMU_USER="$(awk -F '"' '/^[[:space:]]*user[[:space:]]*=/{print $2}' /etc/libvirt/qemu.conf 2>/dev/null | head -n1 || true)"
      fi
      if [[ -z "$${QEMU_GROUP}" ]]; then
        QEMU_GROUP="$(awk -F '"' '/^[[:space:]]*group[[:space:]]*=/{print $2}' /etc/libvirt/qemu.conf 2>/dev/null | head -n1 || true)"
      fi

      if [[ -n "$${QEMU_USER}" ]] && ! id -u "$${QEMU_USER}" >/dev/null 2>&1; then
        QEMU_USER=""
      fi
      if [[ -n "$${QEMU_GROUP}" ]] && ! getent group "$${QEMU_GROUP}" >/dev/null 2>&1; then
        QEMU_GROUP=""
      fi

      if [[ -z "$${QEMU_USER}" ]]; then
        for candidate_user in libvirt-qemu qemu root; do
          if id -u "$${candidate_user}" >/dev/null 2>&1; then
            QEMU_USER="$${candidate_user}"
            break
          fi
        done
      fi

      if [[ -z "$${QEMU_GROUP}" ]]; then
        if [[ -n "$${QEMU_USER}" ]]; then
          QEMU_GROUP="$(id -gn "$${QEMU_USER}" 2>/dev/null || true)"
        fi
      fi

      if [[ -z "$${QEMU_GROUP}" ]]; then
        for candidate_group in libvirt-qemu kvm qemu root; do
          if getent group "$${candidate_group}" >/dev/null 2>&1; then
            QEMU_GROUP="$${candidate_group}"
            break
          fi
        done
      fi

      if [[ -z "$${QEMU_USER}" || -z "$${QEMU_GROUP}" ]]; then
        echo "ERROR: Could not resolve valid qemu runtime user/group (user='$${QEMU_USER}', group='$${QEMU_GROUP}')."
        exit 1
      fi

      CURRENT_SIZE_BYTES="$(sudo qemu-img info --output=json "$${DISK_PATH}" | jq -r '.["virtual-size"] // ."virtual-size"')"

      if [[ "$${CURRENT_SIZE_BYTES}" -lt "$${TARGET_SIZE_BYTES}" ]]; then
        echo "Resizing $${DISK_PATH} from $${CURRENT_SIZE_BYTES} to $${TARGET_SIZE_BYTES} bytes"
        sudo qemu-img resize "$${DISK_PATH}" "$${TARGET_SIZE_BYTES}"
      else
        echo "Disk $${DISK_PATH} already has size $${CURRENT_SIZE_BYTES} bytes (target: $${TARGET_SIZE_BYTES}); skipping resize."
      fi

      sudo chown "$${QEMU_USER}:$${QEMU_GROUP}" "$${DISK_PATH}"
      sudo chmod 0666 "$${DISK_PATH}"
      sudo chmod 0755 "$(dirname "$${DISK_PATH}")"
      if command -v setfacl >/dev/null 2>&1; then
        sudo setfacl -m "u:$${QEMU_USER}:rw" "$${DISK_PATH}" || true
        id -u libvirt-qemu >/dev/null 2>&1 && sudo setfacl -m "u:libvirt-qemu:rw" "$${DISK_PATH}" || true
        id -u qemu >/dev/null 2>&1 && sudo setfacl -m "u:qemu:rw" "$${DISK_PATH}" || true
      fi

      echo "Final disk ownership and mode:"
      sudo stat -c '%U:%G %a %n' "$${DISK_PATH}"
    EOT
  }
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

  depends_on = [null_resource.resize_vm_disk]

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

  qemu_agent = false
}
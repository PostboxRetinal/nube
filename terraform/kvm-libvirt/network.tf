# =============================================================================
# Network Configuration - KVM/Libvirt
# =============================================================================

resource "libvirt_network" "infrastructure" {
  name      = var.network_name
  mode      = "nat"
  domain    = "infrastructure.local"
  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = false
  }

  dns {
    enabled    = true
    local_only = true
  }
}
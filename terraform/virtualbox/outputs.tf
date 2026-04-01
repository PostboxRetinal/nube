# =============================================================================
# Outputs - VirtualBox
# =============================================================================

output "network_info" {
  description = "Network configuration details"
  value = {
    name    = var.network_name
    cidr    = var.network_cidr
    gateway = var.network_gateway
  }
}

output "vm_haproxy" {
  description = "HAProxy VM details"
  value = {
    name        = virtualbox_vm.vm["haproxy"].name
    ip_address  = var.vms.haproxy.ip_address
    memory_mb   = var.vms.haproxy.memory
    vcpu        = var.vms.haproxy.vcpu
    ssh_command = "ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.vms.haproxy.ip_address}"
  }
}

output "vm_microservices" {
  description = "Microservices VM details"
  value = {
    name        = virtualbox_vm.vm["microservices"].name
    ip_address  = var.vms.microservices.ip_address
    memory_mb   = var.vms.microservices.memory
    vcpu        = var.vms.microservices.vcpu
    ssh_command = "ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.vms.microservices.ip_address}"
  }
}

output "haproxy_endpoints" {
  description = "HAProxy access endpoints"
  value = {
    http_endpoint  = "http://${var.vms.haproxy.ip_address}:80"
    stats_endpoint = "http://${var.vms.haproxy.ip_address}:${var.haproxy_stats_port}/stats"
    stats_user     = var.haproxy_stats_user
  }
}

output "microservices_endpoints" {
  description = "Microservices endpoints (direct and via HAProxy)"
  value = {
    for name, svc in var.microservices : name => {
      direct_url  = "http://${var.vms.microservices.ip_address}:${svc.port}"
      haproxy_url = "http://${var.vms.haproxy.ip_address}/api/${name}/"
    }
  }
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = "${var.ansible_playbook_path}/inventory/hosts.yml"
}

output "test_commands" {
  description = "Commands to test the infrastructure"
  sensitive = true
  value = <<-EOT
    
    # Test microservices via HAProxy
    curl http://${var.vms.haproxy.ip_address}/api/users/
    curl http://${var.vms.haproxy.ip_address}/api/products/
    curl http://${var.vms.haproxy.ip_address}/api/orders/
    
    # Access HAProxy stats dashboard
    # URL: http://${var.vms.haproxy.ip_address}:${var.haproxy_stats_port}/stats
    # Username: ${var.haproxy_stats_user}
    # Password: ${var.haproxy_stats_password}
    
    # SSH to VMs
    ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.vms.haproxy.ip_address}
    ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.vms.microservices.ip_address}
    
    # Check Docker containers on microservices VM
    ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.vms.microservices.ip_address} 'docker ps'
  EOT
}
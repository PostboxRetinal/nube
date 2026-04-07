# =============================================================================
# Variables - VirtualBox Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Image Configuration
# -----------------------------------------------------------------------------

variable "vm_image" {
  description = "URL or path to the Ubuntu 22.04 OVA image for VirtualBox"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.ova"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_name" {
  description = "Name of the VirtualBox host-only network adapter"
  type        = string
  default     = "vboxnet0"
}

variable "network_cidr" {
  description = "CIDR block for the infrastructure network"
  type        = string
  default     = "192.168.58.0/24"
}

variable "network_gateway" {
  description = "Gateway IP for the network"
  type        = string
  default     = "192.168.58.1"
}

# -----------------------------------------------------------------------------
# SSH Configuration
# -----------------------------------------------------------------------------

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "/home/vagrant/.ssh/infra_key.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM access"
  type        = string
  default     = "/home/vagrant/.ssh/infra_key"
}

variable "ssh_user" {
  description = "SSH user for VM access"
  type        = string
  default     = "vagrant"
}

variable "ssh_password" {
  description = "SSH password for initial VM configuration"
  type        = string
  default     = "vagrant"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Ansible Configuration
# -----------------------------------------------------------------------------

variable "ansible_playbook_path" {
  description = "Path to Ansible playbooks directory"
  type        = string
  default     = "/home/vagrant/ansible"
}

# -----------------------------------------------------------------------------
# VM Configuration
# -----------------------------------------------------------------------------

variable "vms" {
  description = "Configuration for VMs to be provisioned"
  type = map(object({
    hostname   = string
    ip_address = string
    memory     = number
    vcpu       = number
    role       = string
  }))
  default = {
    haproxy = {
      hostname   = "vm-haproxy"
      ip_address = "192.168.58.20"
      memory     = 1024
      vcpu       = 1
      role       = "haproxy"
    }
    microservices = {
      hostname   = "vm-microservices"
      ip_address = "192.168.58.30"
      memory     = 2048
      vcpu       = 2
      role       = "microservices"
    }
  }
}

# -----------------------------------------------------------------------------
# Control Node
# -----------------------------------------------------------------------------

variable "control_node_ip" {
  description = "IP address of the control node"
  type        = string
  default     = "192.168.57.10"
}

# -----------------------------------------------------------------------------
# HAProxy Configuration
# -----------------------------------------------------------------------------

variable "haproxy_stats_port" {
  description = "Port for HAProxy stats dashboard"
  type        = number
  default     = 8080
}

variable "haproxy_stats_user" {
  description = "Username for HAProxy stats"
  type        = string
  default     = "admin"
}

variable "haproxy_stats_password" {
  description = "Password for HAProxy stats"
  type        = string
  default     = "haproxy_admin_2024"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Microservices Configuration
# -----------------------------------------------------------------------------

variable "microservices" {
  description = "Configuration for Docker microservices"
  type = map(object({
    name  = string
    port  = number
    image = string
  }))
  default = {
    users = {
      name  = "users-service"
      port  = 3001
      image = "nginx:alpine"
    }
    products = {
      name  = "products-service"
      port  = 3002
      image = "nginx:alpine"
    }
    orders = {
      name  = "orders-service"
      port  = 3003
      image = "nginx:alpine"
    }
  }
}
# =============================================================================
# Terraform Version and Provider Requirements - VirtualBox
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "= 0.2.2-alpha.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "virtualbox" {}
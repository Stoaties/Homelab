terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.14"
    }
  }

  cloud {
    organization = "homelabStoaties"  # Updated to your org name

    workspaces {
      name = "homelab-proxmox"
    }
  }
  
  # NOTE: In Terraform Cloud workspace settings, set:
  # Working Directory: terraform/proxmox
}

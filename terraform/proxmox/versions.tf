terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
  }

  cloud {
    organization = "homelabStoaties"  # Updated to your org name

    workspaces {
      name = "Homelab"
    }
  }
  
  # NOTE: In Terraform Cloud workspace settings, set:
  # Working Directory: terraform/proxmox
}

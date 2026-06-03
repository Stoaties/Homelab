terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.14"
    }
  }

  cloud {
    organization = "your-org-name"  # Update with your Terraform Cloud org

    workspaces {
      name = "homelab-proxmox"
    }
  }
}

variable "pm_api_url" {
  type        = string
  sensitive   = false
  description = "Proxmox API URL (e.g., https://proxmox.local:8006)"
}

variable "pm_user" {
  type        = string
  sensitive   = false
  description = "Proxmox username (e.g., root@pam or terraform@pve)"
}

variable "pm_password" {
  type        = string
  sensitive   = true
  description = "Proxmox password"
}

variable "pm_node" {
  type        = string
  sensitive   = false
  description = "Proxmox node name"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID of the cloud-init template to clone (e.g., 9000)"
}

variable "vm_count" {
  type    = number
  default = 3
}

variable "ssh_public_key" {
  type        = string
  sensitive   = true
  description = "SSH public key for VM access"
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key for provisioner connections"
}
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://10.0.0.9:8006/api2/json"
}

variable "proxmox_api_token" {
  description = "Proxmox API token in format 'user@realm!tokenid=secret'"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name to deploy VMs on"
  type        = string
  default     = "pve"  # Update with your node name
}

variable "gateway" {
  description = "Network gateway IP"
  type        = string
  default     = "10.0.0.1"
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "10.0.0.1"  # Or your preferred DNS (1.1.1.1, 8.8.8.8)
}

variable "talos_iso_path" {
  description = "Path to Talos ISO in Proxmox storage"
  type        = string
  default     = "local:iso/talos-amd64.iso"  # Update with actual path
}

variable "vm_storage" {
  description = "Proxmox storage for VM disks"
  type        = string
  default     = "local-lvm"
}

# Control Plane Configuration
variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "control_plane_cpu" {
  description = "CPU cores for control plane nodes"
  type        = number
  default     = 2
}

variable "control_plane_memory" {
  description = "Memory in MB for control plane nodes"
  type        = number
  default     = 4096
}

variable "control_plane_disk_size" {
  description = "Disk size in GB for control plane nodes"
  type        = number
  default     = 50
}

variable "control_plane_ips" {
  description = "IP addresses for control plane nodes"
  type        = list(string)
  default     = ["10.0.1.101", "10.0.1.102", "10.0.1.103"]
}

# Worker Configuration
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "worker_cpu" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
  default     = 8192
}

variable "worker_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 100
}

variable "worker_ips" {
  description = "IP addresses for worker nodes"
  type        = list(string)
  default     = ["10.0.1.201", "10.0.1.202"]
}

variable "network_bridge" {
  description = "Network bridge on Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag (optional)"
  type        = number
  default     = -1  # -1 means no VLAN
}

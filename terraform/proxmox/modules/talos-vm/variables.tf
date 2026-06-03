variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "VM ID in Proxmox"
  type        = number
}

variable "target_node" {
  description = "Proxmox node to deploy VM on"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "disk_size" {
  description = "Disk size (e.g., '50G')"
  type        = string
}

variable "ip_address" {
  description = "Static IP address for the VM"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
}

variable "iso_file" {
  description = "Proxmox datastore file ID for Talos ISO (e.g., 'local:iso/talos-amd64.iso')"
  type        = string
}

variable "storage" {
  description = "Storage pool for VM disk"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag (-1 for no VLAN)"
  type        = number
  default     = -1
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = []
}

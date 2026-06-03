resource "proxmox_virtual_environment_vm" "talos_vm" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.target_node
  description = "Talos OS node managed by Terraform"

  on_boot = true
  
  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    size         = var.disk_size
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
    vlan_id = var.vlan_tag != -1 ? var.vlan_tag : null
  }

  operating_system {
    type = "l26"  # Linux 2.6+ kernel
  }

  bios = "ovmf"

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.gateway
      }
    }
    
    dns {
      servers = [var.nameserver]
    }
  }

  cdrom {
    enabled = true
    file_id = var.iso_file
  }

  lifecycle {
    ignore_changes = [
      cdrom,
    ]
  }
}

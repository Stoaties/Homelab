resource "proxmox_virtual_environment_vm" "talos_vm" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.target_node
  description = "Talos OS node managed by Terraform"

  on_boot = true
  
  # Disable QEMU guest agent - Talos doesn't include it
  agent {
    enabled = false
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

  # REMOVED: initialization block - Talos doesn't use cloud-init
  # Network configuration must be done via Talos config files
  # See talos/scripts/generate-configs.sh

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

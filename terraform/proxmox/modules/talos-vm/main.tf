resource "proxmox_vm_qemu" "talos_vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  desc        = "Talos OS node managed by Terraform"

  # Boot from ISO
  iso         = var.iso_file
  boot        = "order=scsi0;ide2"
  
  # CPU
  cores   = var.cpu_cores
  sockets = 1
  cpu     = "host"
  
  # Memory
  memory = var.memory
  
  # BIOS
  bios = "ovmf"
  
  # Disable QEMU agent (Talos doesn't include it)
  agent = 0
  
  # Boot on start
  onboot  = true
  startup = "order=1"
  
  # Disk
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.storage
          iothread = true
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = var.iso_file
        }
      }
    }
  }
  
  # Network
  network {
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_tag != -1 ? var.vlan_tag : null
  }
  
  # IP Configuration (Static)
  ipconfig0 = "ip=${var.ip_address}/24,gw=${var.gateway}"
  nameserver = var.nameserver
  
  # Tags
  tags = join(";", var.tags)
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      # Ignore changes to network after creation
      network,
      # Ignore ISO changes after first boot
      iso,
    ]
  }
}

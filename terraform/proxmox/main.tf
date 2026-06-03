# Control Plane VMs
module "control_plane" {
  source = "../modules/talos-vm"
  count  = var.control_plane_count

  vm_name      = "talos-cp-${format("%02d", count.index + 1)}"
  vm_id        = 101 + count.index
  target_node  = var.proxmox_node
  
  cpu_cores    = var.control_plane_cpu
  memory       = var.control_plane_memory
  disk_size    = var.control_plane_disk_size
  
  ip_address   = var.control_plane_ips[count.index]
  gateway      = var.gateway
  nameserver   = var.nameserver
  
  iso_file     = var.talos_iso_path
  storage      = var.vm_storage
  network_bridge = var.network_bridge
  vlan_tag     = var.vlan_tag
  
  tags         = ["talos", "control-plane", "kubernetes"]
}

# Worker VMs
module "worker" {
  source = "../modules/talos-vm"
  count  = var.worker_count

  vm_name      = "talos-worker-${format("%02d", count.index + 1)}"
  vm_id        = 201 + count.index
  target_node  = var.proxmox_node
  
  cpu_cores    = var.worker_cpu
  memory       = var.worker_memory
  disk_size    = var.worker_disk_size
  
  ip_address   = var.worker_ips[count.index]
  gateway      = var.gateway
  nameserver   = var.nameserver
  
  iso_file     = var.talos_iso_path
  storage      = var.vm_storage
  network_bridge = var.network_bridge
  vlan_tag     = var.vlan_tag
  
  tags         = ["talos", "worker", "kubernetes"]
}

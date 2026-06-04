# Generate Talos configuration files for control planes
resource "local_file" "control_plane_config" {
  count    = var.control_plane_count
  filename = "${path.module}/../../talos/controlplane-${format("%02d", count.index + 1)}.yaml"
  
  content = templatefile("${path.module}/templates/controlplane.yaml.tpl", {
    hostname         = "talos-cp-${format("%02d", count.index + 1)}"
    ip_address       = var.control_plane_ips[count.index]
    gateway          = var.gateway
    nameserver       = var.nameserver
    cluster_endpoint = "https://${var.control_plane_ips[0]}:6443"
    cluster_name     = "homelab"
  })
}

# Control Plane VMs
module "control_plane" {
  source = "./modules/talos-vm"
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

# Generate Talos configuration files for workers
resource "local_file" "worker_config" {
  count    = var.worker_count
  filename = "${path.module}/../../talos/worker-${format("%02d", count.index + 1)}.yaml"
  
  content = templatefile("${path.module}/templates/worker.yaml.tpl", {
    hostname         = "talos-worker-${format("%02d", count.index + 1)}"
    ip_address       = var.worker_ips[count.index]
    gateway          = var.gateway
    nameserver       = var.nameserver
    cluster_endpoint = "https://${var.control_plane_ips[0]}:6443"
    cluster_name     = "homelab"
  })
}

# Worker VMs
module "worker" {
  source = "./modules/talos-vm"
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

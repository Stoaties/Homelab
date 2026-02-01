#test push
# PROVIDER

terraform {
  cloud {
    organization = "homelabStoaties"
    workspaces {
      name = "Homelab"
    }
    hostname = "app.terraform.io"
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  username = var.pm_user
  password = var.pm_password
  insecure = true
}


# CLOUD-INIT CONFIGURATION
# Using built-in cloud-init parameters instead of cicustom
# k3s installation will be handled via remote-exec provisioner


# K3S SERVER VM

resource "proxmox_virtual_environment_vm" "k3s_server" {
  name      = "k3s-server"
  node_name = var.pm_node

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  initialization {
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    size         = 20
    datastore_id = "local-lvm"
    interface    = "virtio0"
  }
}

# Install k3s on server after VM is ready
resource "null_resource" "k3s_server_install" {
  depends_on = [proxmox_virtual_environment_vm.k3s_server]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ssh_private_key
    host        = proxmox_virtual_environment_vm.k3s_server.ipv4_addresses[1][0]
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "curl -sfL https://get.k3s.io | sh -",
      "until sudo test -f /var/lib/rancher/k3s/server/node-token; do sleep 2; done",
      "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token",
      "sudo chmod 644 /tmp/node-token"
    ]
  }
}


# K3S AGENT VMS

resource "proxmox_virtual_environment_vm" "k3s_agents" {
  count     = var.vm_count - 1
  name      = "k3s-agent-${count.index + 1}"
  node_name = var.pm_node

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    size         = 20
    datastore_id = "local-lvm"
    interface    = "virtio0"
  }
}

# Install k3s agents after server is fully configured
resource "null_resource" "k3s_agent_install" {
  count      = var.vm_count - 1
  depends_on = [null_resource.k3s_server_install]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ssh_private_key
    host        = proxmox_virtual_environment_vm.k3s_agents[count.index].ipv4_addresses[1][0]
  }

  # Copy the private key temporarily to fetch token from server
  provisioner "file" {
    content     = var.ssh_private_key
    destination = "/tmp/ssh_key"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /tmp/ssh_key",
      "cloud-init status --wait",
      "TOKEN=$(ssh -o StrictHostKeyChecking=no -i /tmp/ssh_key ubuntu@${proxmox_virtual_environment_vm.k3s_server.ipv4_addresses[1][0]} 'cat /tmp/node-token')",
      "curl -sfL https://get.k3s.io | K3S_URL=https://${proxmox_virtual_environment_vm.k3s_server.ipv4_addresses[1][0]}:6443 K3S_TOKEN=$TOKEN sh -",
      "rm -f /tmp/ssh_key"
    ]
  }
}


# OUTPUTS

output "k3s_server_ip" {
  value = proxmox_virtual_environment_vm.k3s_server.ipv4_addresses[1][0]
}

output "k3s_agent_ips" {
  value = [for vm in proxmox_virtual_environment_vm.k3s_agents : vm.ipv4_addresses[1][0]]
}


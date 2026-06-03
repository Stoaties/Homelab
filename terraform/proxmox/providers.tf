provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = split("=", var.proxmox_api_token)[0]
  api_token = split("=", var.proxmox_api_token)[1]
  insecure = true
  
  ssh {
    agent = true
  }
}

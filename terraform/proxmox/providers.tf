provider "proxmox" {
  pm_api_url          = var.proxmox_endpoint
  pm_api_token_id     = split("=", var.proxmox_api_token)[0]
  pm_api_token_secret = split("=", var.proxmox_api_token)[1]
  pm_tls_insecure     = true  # Set to false if using valid certificates

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

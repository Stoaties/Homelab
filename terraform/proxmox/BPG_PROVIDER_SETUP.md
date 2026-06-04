# BPG Proxmox Provider Setup

## ✅ Provider Upgraded

Successfully switched from `telmate/proxmox` (v2.9.14) to **`bpg/proxmox` (v0.108.0)** - actively maintained and compatible with modern Proxmox (no VM.Monitor requirement!).

## 🔧 Required: Set Terraform Cloud Variable

The bpg provider requires the variable to be set in Terraform Cloud.

### Go to Workspace Variables:
**https://app.terraform.io/app/homelabStoaties/homelab-proxmox/settings/variables**

### Add This Variable:

**Key:** `proxmox_api_token`  
**Value:** `terraform-prov@pve!terraform-cloud=YOUR_SECRET_HERE`  
**Category:** Terraform variable  
**Sensitive:** ✅ **YES** (check this!)  
**Description:** Proxmox API token in format 'user@realm!tokenid=secret'

### Token Format

The full token must include BOTH the ID and secret:
```
terraform-prov@pve!terraform-cloud=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Get the secret from Proxmox:
1. Login to https://10.0.0.9:8006
2. Datacenter → Permissions → API Tokens
3. Find or create `terraform-prov@pve!terraform-cloud`
4. Copy the full token value

## Test After Setting Variable

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform plan
```

Should work without the VM.Monitor error! 🎉

## What Changed

### Provider Authentication (providers.tf)
```hcl
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  username  = split("=", var.proxmox_api_token)[0]  # terraform-prov@pve!terraform-cloud
  api_token = split("=", var.proxmox_api_token)[1]  # secret part
  insecure  = true
  
  ssh {
    agent = true
  }
}
```

### Resource Type Changed
- Old: `proxmox_vm_qemu` (telmate provider)
- New: `proxmox_virtual_environment_vm` (bpg provider)

### Benefits of bpg/proxmox
- ✅ Actively maintained (latest: v0.108.0)
- ✅ Compatible with modern Proxmox versions
- ✅ No VM.Monitor permission issues
- ✅ Better API coverage
- ✅ Regular updates and bug fixes

## Next Steps

1. Set `proxmox_api_token` variable in Terraform Cloud ☝️
2. Run `terraform plan` - should succeed
3. Run `terraform apply` to create your VMs
4. Follow QUICKSTART.md for Talos bootstrap

## Permissions Required

With bpg/proxmox, your token needs these permissions (grant via PVEVMAdmin role):
- VM.Allocate
- VM.Config.Disk
- VM.Config.CPU
- VM.Config.Memory
- VM.Config.Network
- VM.Config.Options
- VM.PowerMgmt
- Datastore.AllocateSpace

No VM.Monitor needed! ✅

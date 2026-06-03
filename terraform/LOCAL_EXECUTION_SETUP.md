# Terraform Cloud: Local Execution Mode Setup

## Problem
Terraform Cloud runs in the cloud and cannot reach your private Proxmox server (10.0.0.9).

## Solution: Local Execution Mode

Run Terraform on your local machine (which can reach Proxmox) while storing state in Terraform Cloud.

## Steps to Configure

### 1. Change Workspace Execution Mode

Go to your workspace settings:
**https://app.terraform.io/app/homelabStoaties/homelab-proxmox/settings/general**

Scroll to **Execution Mode** section:

- Change from: **Remote** 
- Change to: **Local** ✅

Click **Save settings**

### 2. Set Variables Locally (not in Terraform Cloud)

Since execution is local, you can either:

**Option A: Use terraform.tfvars (Recommended)**

Create `terraform/proxmox/terraform.tfvars`:

```hcl
proxmox_endpoint = "https://10.0.0.9:8006/api2/json"
proxmox_api_token = "terraform-prov@pve!terraform-cloud=YOUR_SECRET_HERE"
```

⚠️ **Never commit terraform.tfvars to git!** (already in .gitignore)

**Option B: Use Environment Variables**

```powershell
$env:TF_VAR_proxmox_endpoint = "https://10.0.0.9:8006/api2/json"
$env:TF_VAR_proxmox_api_token = "terraform-prov@pve!terraform-cloud=YOUR_SECRET_HERE"
```

### 3. Run Terraform Locally

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform init
terraform plan
terraform apply
```

**Terraform will:**
- ✅ Run on your local machine (can reach Proxmox)
- ✅ Store state in Terraform Cloud (safe & shared)
- ✅ Use your local credentials

## Benefits

- 🔒 State stored remotely (backed up, versioned)
- 🏠 Execution runs locally (can reach private networks)
- 👥 Team can share state without sharing credentials
- 🚀 No need to set up agents

## Alternative: Terraform Cloud Agent (Advanced)

If you need remote execution (e.g., for CI/CD), you can set up a self-hosted agent:
https://developer.hashicorp.com/terraform/cloud-docs/agents

But for most homelab use cases, **Local execution mode is perfect!**

## Next Steps

1. ✅ Change execution mode to "Local" in workspace settings
2. ✅ Create `terraform.tfvars` with your credentials
3. ✅ Run `terraform plan`
4. ✅ Run `terraform apply` to create your VMs!

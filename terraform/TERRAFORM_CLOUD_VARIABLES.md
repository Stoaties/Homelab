# Terraform Cloud Workspace Variables Setup

## Required Variables

You need to set these variables in your Terraform Cloud workspace:

### Go to Workspace Settings
https://app.terraform.io/app/homelabStoaties/homelab-proxmox/settings/variables

### Add These Variables

#### 1. proxmox_endpoint
- **Key**: `proxmox_endpoint`
- **Value**: `https://10.0.0.9:8006/api2/json`
- **Category**: Terraform variable
- **Sensitive**: No
- **Description**: Proxmox API endpoint URL

#### 2. proxmox_api_token
- **Key**: `proxmox_api_token`
- **Value**: `terraform-prov@pve!terraform-cloud=YOUR_SECRET_HERE`
- **Category**: Terraform variable
- **Sensitive**: ✅ **YES** (check this!)
- **Description**: Proxmox API token with secret

## How to Get Your Token Secret

If you don't have the secret part of your token, you need to:

### Option 1: Find Existing Token Secret
If you saved it when you created the token, use that.

### Option 2: Create New Token
If you lost the secret, create a new one:

1. Login to Proxmox web UI: https://10.0.0.9:8006
2. Go to: **Datacenter** → **Permissions** → **API Tokens**
3. Find `terraform-prov@pve!terraform-cloud` and click **Edit** or **Remove**
4. If removing, click **Add** to create new token:
   - **User**: `terraform-prov@pve`
   - **Token ID**: `terraform-cloud`
   - **Privilege Separation**: Unchecked (for full access)
5. Click **Add** and **COPY THE SECRET** - you won't see it again!

The format will be:
```
terraform-prov@pve!terraform-cloud=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## After Setting Variables

Once both variables are set in Terraform Cloud:

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform plan
```

Should work!

## Troubleshooting

**Error: "Invalid index"**
- This means the variable is not set or doesn't contain "="
- Make sure you're setting it as a **Terraform variable**, not an Environment variable
- Make sure the value includes the secret part after "="

**Error: "authentication failed"**  
- Token secret is wrong
- Token doesn't have proper permissions
- Endpoint URL is wrong

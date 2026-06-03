# Terraform Cloud Workspace Configuration

## Issue: Module Not Found

When using Terraform Cloud with relative module paths, you need to configure the workspace's working directory.

## Solution

### Configure Workspace Settings

1. Go to your Terraform Cloud workspace: https://app.terraform.io/app/homelabStoaties/homelab-proxmox

2. Navigate to: **Settings** → **General**

3. Set **Terraform Working Directory** to: `terraform/proxmox`

4. Click **Save settings**

### Alternative: Use VCS Workflow

If you prefer VCS-driven workflow instead of CLI-driven:

1. In workspace settings, change to **Version Control Workflow**
2. Connect to your GitHub repository
3. Set **Terraform Working Directory** to: `terraform/proxmox`
4. Auto-apply or manual apply as preferred

### Why This Is Needed

Terraform Cloud only uploads files from the working directory by default. Since our module is at `terraform/modules/talos-vm/` and our configuration is at `terraform/proxmox/`, we need to tell Terraform Cloud where the root is.

The module source path `../modules/talos-vm` means "go up one directory to `terraform/`, then into `modules/talos-vm/`". By setting the working directory to `terraform/proxmox`, Terraform Cloud will upload the entire `terraform/` directory structure, making the modules accessible.

## After Configuration

1. **Commit and push** your code to GitHub
2. If using VCS workflow, Terraform Cloud will automatically plan
3. If using CLI workflow, run `terraform plan` again from `terraform/proxmox/`

## Verification

After setting the working directory, when you run `terraform plan`, you should see:

```
Initializing modules...
- control_plane in ../modules/talos-vm
- worker in ../modules/talos-vm
```

Without errors!

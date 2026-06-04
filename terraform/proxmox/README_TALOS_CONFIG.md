# Terraform-Managed Talos Configuration

This Terraform configuration automatically generates per-node Talos configuration files with static IP addresses.

## How It Works

1. **Templates**: Terraform uses `templates/controlplane.yaml.tpl` and `templates/worker.yaml.tpl` as base configurations
2. **Generation**: For each VM, Terraform generates a unique config file with the static IP address baked in
3. **Output**: Config files are created in `../../talos/` directory:
   - `controlplane-01.yaml`, `controlplane-02.yaml`, `controlplane-03.yaml`
   - `worker-01.yaml`, `worker-02.yaml`

## Configuration Variables

Static IPs are defined in `terraform.tfvars`:
```hcl
control_plane_ips = ["10.0.1.101", "10.0.1.102", "10.0.1.103"]
worker_ips        = ["10.0.1.201", "10.0.1.202"]
gateway           = "10.0.0.1"
nameserver        = "8.8.8.8"
```

## Workflow

### 1. Generate Configs and Deploy VMs
```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform init
terraform plan
terraform apply
```

This will:
- Generate Talos config files with static IPs
- Create VMs in Proxmox
- VMs will boot with DHCP temporarily

### 2. Apply Configs to VMs

After VMs are created, apply the generated configs:

```powershell
cd Z:\VS_Code\Homelab\talos

# Get DHCP IPs from Proxmox console (10.0.0.x)
# Then apply configs (nodes will reboot and get static IPs)

talosctl apply-config --insecure --nodes <DHCP-IP> --file controlplane-01.yaml
talosctl apply-config --insecure --nodes <DHCP-IP> --file controlplane-02.yaml
talosctl apply-config --insecure --nodes <DHCP-IP> --file controlplane-03.yaml
talosctl apply-config --insecure --nodes <DHCP-IP> --file worker-01.yaml
talosctl apply-config --insecure --nodes <DHCP-IP> --file worker-02.yaml
```

### 3. Bootstrap Cluster

After nodes reboot with static IPs:

```powershell
$env:TALOSCONFIG = "Z:\VS_Code\Homelab\talos\talosconfig"
talosctl config endpoint 10.0.1.101 10.0.1.102 10.0.1.103
talosctl bootstrap --nodes 10.0.1.101
```

### 4. Get Kubeconfig

```powershell
talosctl kubeconfig --nodes 10.0.1.101
kubectl get nodes
```

## Advantages Over Manual Config

✅ **IP addresses are defined once** in `terraform.tfvars`
✅ **Configs are auto-generated** with correct IPs
✅ **No manual editing** of YAML files
✅ **Easy to add more nodes** - just update `terraform.tfvars`
✅ **Infrastructure as Code** - everything versioned in Git

## Modifying Network Settings

To change IPs or add nodes:

1. Edit `terraform.tfvars`:
   ```hcl
   control_plane_count = 5  # Add 2 more control planes
   control_plane_ips = ["10.0.1.101", "10.0.1.102", "10.0.1.103", "10.0.1.104", "10.0.1.105"]
   ```

2. Run `terraform apply` - configs will regenerate automatically

3. Apply new configs to new VMs

## Template Customization

Edit templates to change:
- Kubernetes version
- Talos installer version
- Pod/Service subnets
- Kubelet settings
- Additional machine config options

Templates are in: `terraform/proxmox/templates/`

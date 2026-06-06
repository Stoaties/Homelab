# DHCP-Based Talos Cluster Deployment

This setup uses DHCP for all node IP addresses, making deployment simpler and avoiding static IP conflicts.

## Prerequisites

- ✅ DHCP server on your network (10.0.0.1)
- ✅ Proxmox accessible at 10.0.0.9
- ✅ `talosctl` installed

## Deployment Steps

### Step 1: Deploy VMs with Terraform

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform init
terraform plan
terraform apply
```

This creates:
- 3 control plane VMs (talos-cp-01, talos-cp-02, talos-cp-03)
- 2 worker VMs (talos-worker-01, talos-worker-02)
- Talos config files with DHCP networking in `../../talos/`

⏱️ Takes ~5-10 minutes

### Step 2: Find DHCP IP Addresses

After VMs boot, note their DHCP-assigned IPs from Proxmox console:

**Option A: Proxmox UI**
1. Open each VM console
2. Look for IP in the Talos dashboard

**Option B: Check DHCP leases**
```powershell
ssh root@10.0.0.9 "cat /var/lib/misc/dnsmasq.leases"
```

**Example IPs:**
- talos-cp-01: `10.0.0.185`
- talos-cp-02: `10.0.0.186`
- talos-cp-03: `10.0.0.187`
- talos-worker-01: `10.0.0.188`
- talos-worker-02: `10.0.0.189`

### Step 3: Update Cluster Endpoint

**Important:** Update the cluster endpoint to the first control plane's IP:

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox

# Edit terraform.tfvars or variables.tf
# Set: cluster_endpoint = "https://10.0.0.185:6443"  # Use your actual IP

# Regenerate configs with correct endpoint
terraform apply
```

### Step 4: Apply Talos Configurations

```powershell
cd Z:\VS_Code\Homelab\talos

# Apply to control planes (use their DHCP IPs)
talosctl apply-config --insecure --nodes 10.0.0.185 --file controlplane-01.yaml
talosctl apply-config --insecure --nodes 10.0.0.186 --file controlplane-02.yaml
talosctl apply-config --insecure --nodes 10.0.0.187 --file controlplane-03.yaml

# Apply to workers
talosctl apply-config --insecure --nodes 10.0.0.188 --file worker-01.yaml
talosctl apply-config --insecure --nodes 10.0.0.189 --file worker-02.yaml
```

Nodes will acknowledge and install Talos to disk. They may reboot.

### Step 5: Remove ISO and Reboot

After Talos is installed, VMs need to boot from disk:

**Option A: Proxmox UI** (per VM)
1. Hardware → CD/DVD Drive → Edit
2. Select "Do not use any media"
3. Reboot VM

**Option B: SSH to Proxmox**
```bash
ssh root@10.0.0.9
qm set 101 --ide2 none && qm reboot 101  # cp-01
qm set 102 --ide2 none && qm reboot 102  # cp-02
qm set 103 --ide2 none && qm reboot 103  # cp-03
qm set 201 --ide2 none && qm reboot 201  # worker-01
qm set 202 --ide2 none && qm reboot 202  # worker-02
```

Wait ~2 minutes for nodes to boot from disk.

### Step 6: Configure talosctl

```powershell
$env:TALOSCONFIG = "Z:\VS_Code\Homelab\talos\talosconfig"

# Point to all control planes (use their DHCP IPs)
talosctl config endpoint 10.0.0.185 10.0.0.186 10.0.0.187
talosctl config node 10.0.0.185
```

### Step 7: Bootstrap Cluster

```powershell
# Bootstrap first control plane
talosctl bootstrap --nodes 10.0.0.185

# Wait ~2-3 minutes for etcd initialization
```

### Step 8: Verify Cluster

```powershell
# Check health
talosctl health --nodes 10.0.0.185

# Get kubeconfig
talosctl kubeconfig --nodes 10.0.0.185

# View nodes
kubectl get nodes
```

**Expected output:**
```
NAME              STATUS   ROLES           AGE   VERSION
talos-cp-01       Ready    control-plane   5m    v1.31.0
talos-cp-02       Ready    control-plane   5m    v1.31.0
talos-cp-03       Ready    control-plane   5m    v1.31.0
talos-worker-01   Ready    <none>          5m    v1.31.0
talos-worker-02   Ready    <none>          5m    v1.31.0
```

## Important Notes

### DHCP Reservations (Recommended)

For production, configure DHCP reservations based on MAC addresses so IPs don't change:

```bash
# Get MAC addresses
talosctl get links -n 10.0.0.185 --insecure
```

Then add reservations in your router/DHCP server.

### Cluster Endpoint

The cluster endpoint points to the first control plane. If that node goes down, you'll need to:
- Update the endpoint to another control plane IP
- OR set up a load balancer VIP for HA

### Troubleshooting

**VMs stuck booting from ISO:**
- Console shows "halt_if_installed" message
- Remove ISO (Step 5) and reboot

**Can't reach nodes after config apply:**
- Nodes may have rebooted with same DHCP IP
- Wait 2 minutes and retry

**Bootstrap fails:**
- Ensure all 3 control planes are running
- Check endpoint IP is correct: `talosctl version --nodes 10.0.0.185`

## Next Steps

- Install CNI (Cilium/Calico) if needed
- Deploy ArgoCD
- Configure ingress controller
- Set up monitoring

## Advantages of DHCP Setup

✅ No IP conflicts  
✅ Works with any network configuration  
✅ Simpler deployment  
✅ Easy to add nodes  

⚠️ **Recommendation:** Set up DHCP reservations or a load balancer VIP for production use.

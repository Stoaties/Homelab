# Homelab Kubernetes Cluster Deployment Guide

## Prerequisites
- [ ] Proxmox endpoint accessible at https://10.0.0.9:8006
- [ ] Terraform Cloud workspace configured with `proxmox_api_token`
- [ ] Talos ISO uploaded to Proxmox
- [ ] `talosctl` installed locally

## Step 1: Deploy VMs with Terraform

```powershell
cd Z:\VS_Code\Homelab\terraform\proxmox
terraform plan
terraform apply
```

**Expected result:**
- 3 control plane VMs: `talos-cp-01`, `talos-cp-02`, `talos-cp-03`
- 2 worker VMs: `talos-worker-01`, `talos-worker-02`
- All VMs will boot with **DHCP IPs** (10.0.0.x range initially)

⏱️ This takes ~2-3 minutes per VM

## Step 2: Find the DHCP IP Addresses

Open Proxmox web UI and check each VM's console or use:

```powershell
# From Proxmox host, check DHCP leases
ssh root@10.0.0.9
cat /var/lib/misc/dnsmasq.leases
```

**Note down the IPs:**
- talos-cp-01: `10.0.0.___`
- talos-cp-02: `10.0.0.___`
- talos-cp-03: `10.0.0.___`
- talos-worker-01: `10.0.0.___`
- talos-worker-02: `10.0.0.___`

## Step 3: Generate Talos Configuration Files

```bash
cd Z:\VS_Code\Homelab\talos\scripts
bash generate-configs.sh
```

This creates:
- `controlplane.yaml` - base control plane config
- `worker.yaml` - base worker config
- `talosconfig` - CLI credentials
- `secrets.yaml` - cluster secrets

## Step 4: Patch Network Configuration into Configs

**Important:** The generated configs don't have static IPs yet. You need to create per-node configs with network settings.

### Option A: Automated (Recommended)

Create `patch-network.sh`:

```bash
#!/bin/bash
# Creates per-node configs with static IP addresses

# Control plane IPs (desired static IPs)
declare -A CP_IPS=([1]="10.0.1.101" [2]="10.0.1.102" [3]="10.0.1.103")

# Worker IPs (desired static IPs)
declare -A WORKER_IPS=([1]="10.0.1.201" [2]="10.0.1.202")

GATEWAY="10.0.0.1"
NAMESERVER="8.8.8.8"

# Generate control plane configs with static IPs
for i in 1 2 3; do
  cat > "../controlplane-0${i}.yaml" <<EOF
version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  network:
    hostname: talos-cp-0${i}
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - ${CP_IPS[$i]}/24
        routes:
          - network: 0.0.0.0/0
            gateway: ${GATEWAY}
    nameservers:
      - ${NAMESERVER}
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:v1.7.0
    bootloader: true
    wipe: false
  kubelet:
    image: ghcr.io/siderolabs/kubelet:v1.30.0
cluster:
  controlPlane:
    endpoint: https://10.0.1.101:6443
  clusterName: homelab
  network:
    dnsDomain: cluster.local
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
EOF
  echo "Created controlplane-0${i}.yaml with IP ${CP_IPS[$i]}"
done

# Generate worker configs with static IPs
for i in 1 2; do
  cat > "../worker-0${i}.yaml" <<EOF
version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  network:
    hostname: talos-worker-0${i}
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - ${WORKER_IPS[$i]}/24
        routes:
          - network: 0.0.0.0/0
            gateway: ${GATEWAY}
    nameservers:
      - ${NAMESERVER}
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:v1.7.0
    bootloader: true
    wipe: false
  kubelet:
    image: ghcr.io/siderolabs/kubelet:v1.30.0
cluster:
  controlPlane:
    endpoint: https://10.0.1.101:6443
  clusterName: homelab
  network:
    dnsDomain: cluster.local
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
EOF
  echo "Created worker-0${i}.yaml with IP ${WORKER_IPS[$i]}"
done

echo "✅ All per-node configs created!"
```

Run it:
```bash
bash patch-network.sh
```

### Option B: Manual Edit

Edit each YAML file and add the network section under `machine:`.

## Step 5: Apply Talos Configurations to VMs

**Use the DHCP IPs from Step 2:**

```bash
# Apply to control plane 01 (use DHCP IP)
talosctl apply-config --insecure \
  --nodes 10.0.0.40 \
  --file ../controlplane-01.yaml

# Apply to control plane 02
talosctl apply-config --insecure \
  --nodes 10.0.0.41 \
  --file ../controlplane-02.yaml

# Apply to control plane 03
talosctl apply-config --insecure \
  --nodes 10.0.0.42 \
  --file ../controlplane-03.yaml

# Apply to worker 01
talosctl apply-config --insecure \
  --nodes 10.0.0.43 \
  --file ../worker-01.yaml

# Apply to worker 02
talosctl apply-config --insecure \
  --nodes 10.0.0.44 \
  --file ../worker-02.yaml
```

**What happens:**
- Nodes receive their configs
- Nodes **reboot** and come up with **static IPs** (10.0.1.x)
- Wait ~2 minutes for reboot

## Step 6: Configure talosctl

```bash
# Set endpoints to NEW static IPs
export TALOSCONFIG="Z:\VS_Code\Homelab\talos\talosconfig"
talosctl config endpoint 10.0.1.101 10.0.1.102 10.0.1.103
talosctl config node 10.0.1.101
```

## Step 7: Bootstrap the Cluster

```bash
# Bootstrap first control plane
talosctl bootstrap --nodes 10.0.1.101

# Wait ~2-3 minutes for etcd to initialize
```

## Step 8: Verify Cluster Health

```bash
# Check cluster health
talosctl health --nodes 10.0.1.101

# Get kubeconfig
talosctl kubeconfig --nodes 10.0.1.101

# Verify nodes
kubectl get nodes

# Expected output:
# NAME              STATUS   ROLES           AGE   VERSION
# talos-cp-01       Ready    control-plane   2m    v1.30.0
# talos-cp-02       Ready    control-plane   2m    v1.30.0
# talos-cp-03       Ready    control-plane   2m    v1.30.0
# talos-worker-01   Ready    <none>          2m    v1.30.0
# talos-worker-02   Ready    <none>          2m    v1.30.0
```

## Step 9: Access Your Cluster

```bash
# View cluster info
kubectl cluster-info

# Deploy a test app
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Check deployment
kubectl get pods
kubectl get svc
```

## Common Issues

### VMs not getting DHCP
- Check Proxmox network bridge is correct
- Verify VLAN tag if using VLANs

### Can't reach nodes at DHCP IPs
- Check firewall rules
- Verify network connectivity from your machine to 10.0.0.x

### Nodes don't reboot after apply-config
- Nodes should auto-reboot after receiving config
- If not, manually reboot from Proxmox console

### Bootstrap fails
- Ensure node is fully booted (check with `talosctl dashboard -n 10.0.1.101`)
- Verify all 3 control planes are reachable

### Nodes stuck in NotReady
- Check CNI is installed: `kubectl get pods -n kube-system`
- May need to install Cilium/Calico manually

## Next Steps

After cluster is up:
1. Install CNI if not auto-installed (Cilium/Calico)
2. Deploy ArgoCD
3. Configure storage (if needed)
4. Set up ingress controller

## Quick Reference Commands

```bash
# Talos dashboard
talosctl dashboard -n 10.0.1.101

# Logs from a node
talosctl logs -n 10.0.1.101

# List containers
talosctl containers -n 10.0.1.101

# Restart a node
talosctl reboot -n 10.0.1.201

# Get node config
talosctl get config -n 10.0.1.101
```

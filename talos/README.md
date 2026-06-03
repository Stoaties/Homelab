# Talos OS Configuration Templates

This directory contains Talos OS configuration templates for the homelab Kubernetes cluster.

## Quick Start

### 1. Generate Configurations

Run the generation script to create Talos configs:

```bash
cd talos/scripts
chmod +x generate-configs.sh apply-configs.sh
./generate-configs.sh
```

This will generate:
- `controlplane.yaml` - Control plane node configuration
- `worker.yaml` - Worker node configuration
- `talosconfig` - Talosctl client configuration
- `secrets.yaml` - Cluster secrets (⚠️ **DO NOT COMMIT**)

### 2. Apply Configurations

After VMs are provisioned via Terraform, apply the Talos configurations:

```bash
./apply-configs.sh
```

### 3. Bootstrap Cluster

Bootstrap the first control plane node:

```bash
talosctl bootstrap -n 10.0.1.101
```

### 4. Get Kubeconfig

Retrieve the kubeconfig to access your cluster:

```bash
talosctl kubeconfig -n 10.0.1.101
```

Test cluster access:

```bash
kubectl get nodes
```

## Configuration Customization

### Control Plane Configuration

Edit `controlplane.yaml.example` to customize:
- Network settings
- Kubelet configuration
- API server settings
- etcd configuration
- CNI (Container Network Interface)

### Worker Configuration

Edit `worker.yaml.example` to customize:
- Network settings
- Kubelet configuration
- Container runtime settings

## Common Tasks

### Check Node Status

```bash
talosctl -n 10.0.1.101 get members
```

### View Cluster Health

```bash
talosctl -n 10.0.1.101 health
```

### Get Logs

```bash
talosctl -n 10.0.1.101 logs
```

### Dashboard Access

```bash
talosctl -n 10.0.1.101 dashboard
```

### Upgrade Talos

```bash
talosctl -n <node-ip> upgrade --image ghcr.io/siderolabs/installer:v1.7.0
```

## Network Configuration

- **Cluster Endpoint**: https://10.0.1.101:6443
- **Control Planes**: 10.0.1.101, 10.0.1.102, 10.0.1.103
- **Workers**: 10.0.1.201, 10.0.1.202
- **Gateway**: 10.0.0.1

## Troubleshooting

### Node Not Responding

Check if VM is running in Proxmox and network is configured correctly.

### Bootstrap Fails

Ensure all control plane nodes are reachable and configurations are applied.

### Pods Not Starting

Check CNI is properly installed:
```bash
kubectl get pods -n kube-system
```

## Security Notes

⚠️ **Never commit these files to git:**
- `secrets.yaml`
- `talosconfig`
- `*.kubeconfig`

These files contain sensitive cluster credentials!

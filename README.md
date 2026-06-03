# Homelab Infrastructure as Code

This repository contains the complete infrastructure-as-code setup for my homelab Kubernetes cluster, built on Proxmox with Talos OS and managed via GitOps with ArgoCD.

## 🏗️ Stack

- **Proxmox VE**: Hypervisor for VM hosting
- **Terraform**: Infrastructure provisioning
- **Talos OS**: Immutable Kubernetes OS
- **Kubernetes**: Container orchestration (via Talos)
- **ArgoCD**: GitOps continuous delivery

## 📊 Architecture

### Network Configuration
- **Gateway**: 10.0.0.1
- **Proxmox**: 10.0.0.9
- **Control Planes**: 10.0.1.101 - 10.0.1.103 (3 nodes)
- **Workers**: 10.0.1.201 - 10.0.1.202 (2 nodes)

### Cluster Topology
```
┌─────────────────────────────────────────┐
│         Proxmox Cluster (10.0.0.9)       │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │   Control Plane (3 nodes)         │   │
│  │   - talos-cp-01   (10.0.1.101)   │   │
│  │   - talos-cp-02   (10.0.1.102)   │   │
│  │   - talos-cp-03   (10.0.1.103)   │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │   Workers (2 nodes)               │   │
│  │   - talos-worker-01 (10.0.1.201) │   │
│  │   - talos-worker-02 (10.0.1.202) │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
1. Proxmox VE installed and accessible
2. Terraform installed (v1.5+)
3. Terraform Cloud account (for remote state)
4. Talos CLI (`talosctl`)
5. kubectl

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd homelab-iac
```

### 2. Configure Terraform Cloud
Set up workspace variables in Terraform Cloud:
- `proxmox_api_token` (sensitive)
- `proxmox_endpoint` = `https://10.0.0.9:8006/api2/json/`

### 3. Provision Infrastructure
```bash
cd terraform/proxmox
terraform init
terraform plan
terraform apply
```

### 4. Bootstrap Talos
```bash
cd ../../talos
./scripts/generate-configs.sh
./scripts/apply-configs.sh
```

### 5. Deploy ArgoCD
```bash
kubectl apply -k argocd/install/
```

See [docs/setup-guide.md](docs/setup-guide.md) for detailed instructions.

## 📁 Repository Structure

```
.
├── terraform/          # Infrastructure provisioning
│   ├── proxmox/       # Proxmox provider & VMs
│   └── modules/       # Reusable Terraform modules
├── talos/             # Talos OS configurations
├── argocd/            # ArgoCD setup & applications
├── apps/              # Application manifests
└── docs/              # Documentation
```

## 🔒 Security

- All secrets are stored in Terraform Cloud workspace variables
- Sensitive files are excluded via `.gitignore`
- Talos provides immutable infrastructure
- GitOps ensures auditable deployments

## 📖 Documentation

- [Setup Guide](docs/setup-guide.md) - Complete deployment walkthrough
- [Proxmox Setup](docs/proxmox-setup.md) - Proxmox configuration details
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## 🛠️ Maintenance

### Update Talos
```bash
talosctl upgrade --nodes <node-ip> --image ghcr.io/siderolabs/installer:v1.7.0
```

### Update Applications
Commit changes to `apps/` directory - ArgoCD will auto-sync.

## 📝 License

MIT License - Feel free to use for your own homelab!

# Homelab Setup Guide

This guide walks you through deploying the complete homelab infrastructure from scratch.

## Prerequisites

### Required Software
- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Talosctl](https://www.talos.dev/latest/introduction/getting-started/) (Talos CLI)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (Kubernetes CLI)
- [Git](https://git-scm.com/downloads)

### Required Access
- Proxmox VE cluster access
- Terraform Cloud account
- GitHub account (for repository)

### Network Requirements
- Gateway: 10.0.0.1
- Proxmox accessible at: https://10.0.0.9:8006
- Available IP ranges:
  - Control Planes: 10.0.1.101 - 10.0.1.103
  - Workers: 10.0.1.201 - 10.0.1.202

---

## Phase 1: Proxmox Preparation

### 1.1 Download Talos ISO

1. Visit [Talos Releases](https://github.com/siderolabs/talos/releases)
2. Download the latest `talos-amd64.iso`
3. Upload to Proxmox:

```bash
# Option A: Upload via Proxmox Web UI
# Datacenter → <node> → local → ISO Images → Upload

# Option B: Upload via CLI (from Proxmox host)
wget https://github.com/siderolabs/talos/releases/download/v1.7.0/talos-amd64.iso
mv talos-amd64.iso /var/lib/vz/template/iso/
```

### 1.2 Create Proxmox API Token

1. Login to Proxmox web interface
2. Navigate to: Datacenter → Permissions → API Tokens
3. Click "Add" and create a token:
   - **User**: root@pam (or create dedicated user)
   - **Token ID**: terraform
   - **Privilege Separation**: Unchecked (for full permissions)
4. **Save the token secret** - you won't see it again!
5. Format: `root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

---

## Phase 2: Terraform Cloud Setup

### 2.1 Create Organization & Workspace

1. Go to [Terraform Cloud](https://app.terraform.io/)
2. Create organization (or use existing)
3. Create workspace:
   - **Type**: CLI-driven workflow
   - **Name**: homelab-proxmox

### 2.2 Configure Workspace Variables

Add these variables in workspace settings:

| Variable Name | Value | Sensitive |
|--------------|-------|-----------|
| `proxmox_endpoint` | `https://10.0.0.9:8006/api2/json` | No |
| `proxmox_api_token` | `terraform-prov@pve!terraform-cloud=xxx...` | **Yes** |

### 2.3 Update Terraform Configuration

Edit `terraform/proxmox/versions.tf`:

```hcl
cloud {
  organization = "your-org-name"  # <-- Change this

  workspaces {
    name = "homelab-proxmox"
  }
}
```

---

## Phase 3: Deploy Infrastructure

### 3.1 Clone Repository

```bash
git clone https://github.com/your-username/homelab-iac.git
cd homelab-iac
```

### 3.2 Configure Terraform Variables

```bash
cd terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
proxmox_node = "pve"  # Your Proxmox node name

talos_iso_path = "local:iso/talos-amd64.iso"
vm_storage     = "local-lvm"

network_bridge = "vmbr0"
```

### 3.3 Initialize Terraform

```bash
terraform init
```

You'll be prompted to login to Terraform Cloud.

### 3.4 Plan Deployment

```bash
terraform plan
```

Review the plan - you should see 5 VMs to be created.

### 3.5 Deploy VMs

```bash
terraform apply
```

Type `yes` to confirm.

This will create:
- 3 Control Plane VMs (talos-cp-01, talos-cp-02, talos-cp-03)
- 2 Worker VMs (talos-worker-01, talos-worker-02)

**Duration**: ~5-10 minutes

---

## Phase 4: Bootstrap Talos Cluster

### 4.1 Generate Talos Configurations

```bash
cd ../../talos/scripts
chmod +x *.sh
./generate-configs.sh
```

This creates:
- `controlplane.yaml` - Control plane configuration
- `worker.yaml` - Worker configuration
- `talosconfig` - Talosctl client config
- `secrets.yaml` - Cluster secrets

### 4.2 Apply Configurations to Nodes

```bash
./apply-configs.sh
```

This will:
1. Wait for each node to be reachable
2. Apply appropriate configuration
3. Take ~2-3 minutes per node

### 4.3 Bootstrap Kubernetes

Bootstrap the first control plane:

```bash
cd ..
talosctl bootstrap -n 10.0.1.101
```

Wait for cluster to be ready (~3-5 minutes):

```bash
talosctl -n 10.0.1.101 health
```

### 4.4 Retrieve Kubeconfig

```bash
talosctl kubeconfig -n 10.0.1.101
```

This saves kubeconfig to `~/.kube/config`.

### 4.5 Verify Cluster

```bash
kubectl get nodes
```

Expected output:
```
NAME              STATUS   ROLES           AGE   VERSION
talos-cp-01       Ready    control-plane   5m    v1.30.0
talos-cp-02       Ready    control-plane   5m    v1.30.0
talos-cp-03       Ready    control-plane   5m    v1.30.0
talos-worker-01   Ready    <none>          5m    v1.30.0
talos-worker-02   Ready    <none>          5m    v1.30.0
```

---

## Phase 5: Deploy ArgoCD

### 5.1 Install ArgoCD

```bash
cd ../../argocd
kubectl apply -k install/
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=300s
```

### 5.2 Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

**Save this password!**

### 5.3 Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open browser: https://localhost:8080

- **Username**: admin
- **Password**: (from step 5.2)

### 5.4 Deploy Homelab Project & Root App

```bash
kubectl apply -f projects/homelab.yaml
kubectl apply -f applications/root-app.yaml
```

**Important**: Update the Git repository URL in `applications/root-app.yaml` first!

---

## Phase 6: Next Steps

### Install CNI (Container Network Interface)

Talos comes without a CNI. Install one:

**Cilium (Recommended)**:
```bash
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.15/install/kubernetes/quick-install.yaml
```

**Flannel**:
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### Deploy Applications

Add your applications to `apps/` directory and commit:

```bash
git add apps/my-app
git commit -m "Add my-app"
git push
```

ArgoCD will auto-sync!

### Install Monitoring (Optional)

```bash
# Prometheus + Grafana via kube-prometheus-stack
kubectl create namespace monitoring
argocd app create kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --helm-chart kube-prometheus-stack \
  --revision 56.0.0 \
  --dest-namespace monitoring \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated
```

---

## Troubleshooting

### VMs Not Booting
- Check Proxmox console for each VM
- Verify ISO is correctly uploaded
- Check VM has enough resources

### Talos Config Apply Fails
- Verify VMs are reachable: `ping 10.0.1.101`
- Check talosctl version matches Talos version
- Wait longer for VMs to fully boot

### Kubernetes Not Ready
- Check control plane logs: `talosctl -n 10.0.1.101 logs`
- Verify etcd is healthy: `talosctl -n 10.0.1.101 etcd members`
- Install CNI if not done

### ArgoCD Can't Access Repository
- Verify Git repository URL in `root-app.yaml`
- If private repo, add credentials in ArgoCD UI
- Check ArgoCD has network access

---

## Summary

You now have:
✅ 5-node Kubernetes cluster on Proxmox  
✅ Talos OS for immutable infrastructure  
✅ ArgoCD for GitOps deployments  
✅ Infrastructure fully codified  

**Next**: Start deploying your applications! 🚀

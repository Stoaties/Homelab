# Quick Start - Homelab Deployment

## Prerequisites Checklist
- [ ] Proxmox VE installed and accessible at 10.0.0.9
- [ ] Terraform Cloud account created
- [ ] Talos ISO downloaded and uploaded to Proxmox
- [ ] Proxmox API token generated
- [ ] Git repository created on GitHub

## Step-by-Step Deployment

### 1️⃣ Terraform Cloud Setup (5 minutes)
```bash
# Login to Terraform Cloud: https://app.terraform.io/
# Create organization (or use existing)
# Create workspace: "homelab-proxmox"
# Add workspace variables:
#   - proxmox_endpoint = "https://10.0.0.9:8006/api2/json"
#   - proxmox_api_token = "root@pam!terraform=xxx..." (sensitive)

# Update terraform/proxmox/versions.tf with your org name
```

### 2️⃣ Deploy VMs with Terraform (10 minutes)
```bash
cd terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox node name

terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```

**Result:** 5 VMs created (3 control planes, 2 workers)

### 3️⃣ Bootstrap Talos Cluster (15 minutes)
```bash
cd ../../talos/scripts
chmod +x *.sh

# Generate configurations
./generate-configs.sh

# Apply to all nodes (waits for VMs to be ready)
./apply-configs.sh

# Bootstrap first control plane
cd ..
talosctl bootstrap -n 10.0.1.101

# Wait for cluster (2-3 minutes)
talosctl -n 10.0.1.101 health

# Get kubeconfig
talosctl kubeconfig -n 10.0.1.101

# Verify
kubectl get nodes
```

**Result:** 5-node Kubernetes cluster running

### 4️⃣ Install CNI (2 minutes)
```bash
# Choose ONE:

# Option A: Cilium (recommended)
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.15/install/kubernetes/quick-install.yaml

# Option B: Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verify nodes become Ready
kubectl get nodes -w
```

**Result:** Network connectivity between pods

### 5️⃣ Deploy ArgoCD (5 minutes)
```bash
cd ../../argocd

# Deploy ArgoCD
kubectl apply -k install/

# Wait for ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo

# Access UI (in new terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
# Login: admin / <password-from-above>
```

**Result:** ArgoCD ready for GitOps

### 6️⃣ Configure GitOps (5 minutes)
```bash
# Update root-app.yaml with your Git repo URL
# Edit: argocd/applications/root-app.yaml
#   repoURL: https://github.com/YOUR-USERNAME/homelab-iac.git

# Deploy root app
kubectl apply -f projects/homelab.yaml
kubectl apply -f applications/root-app.yaml

# Push to GitHub
git remote add origin https://github.com/YOUR-USERNAME/homelab-iac.git
git push -u origin agents/homelab-infrastructure-as-code
```

**Result:** GitOps pipeline active!

## ✅ You're Done!

Your homelab is now:
- ✅ Infrastructure as Code (Terraform)
- ✅ Immutable OS (Talos)
- ✅ Container orchestration (Kubernetes)
- ✅ GitOps deployment (ArgoCD)

## 🚀 What's Next?

### Add Your First App
```bash
# Create app directory
mkdir -p apps/hello-world

# Create deployment
cat > apps/hello-world/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello
        image: nginxdemos/hello:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  selector:
    app: hello-world
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Commit and push
git add apps/hello-world
git commit -m "Add hello-world app"
git push

# Watch ArgoCD auto-deploy!
```

### Recommended Next Steps
1. **Ingress Controller**: Expose services externally
2. **Cert Manager**: Automatic TLS certificates
3. **Monitoring**: Prometheus + Grafana
4. **Storage**: Longhorn for persistent volumes
5. **Secrets**: Sealed Secrets or External Secrets

See `apps/README.md` for more examples!

## 📚 Documentation

- **Full Setup Guide**: `docs/setup-guide.md`
- **Proxmox Details**: `docs/proxmox-setup.md`
- **Troubleshooting**: `docs/troubleshooting.md`
- **Talos Guide**: `talos/README.md`
- **ArgoCD Guide**: `argocd/README.md`
- **Apps Guide**: `apps/README.md`

## 🆘 Need Help?

Check `docs/troubleshooting.md` for common issues.

## ⏱️ Total Time: ~45 minutes
(Terraform: 10min, Talos: 15min, CNI: 2min, ArgoCD: 5min, GitOps: 5min)

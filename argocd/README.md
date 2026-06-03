# ArgoCD Installation Guide

This directory contains the ArgoCD installation manifests for the homelab cluster.

## Installation

### 1. Deploy ArgoCD

```bash
kubectl apply -k argocd/install/
```

Wait for all pods to be ready:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 2. Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Access ArgoCD UI

**Option A: Port Forward**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access: https://localhost:8080

**Option B: Expose via LoadBalancer (if available)**

Edit `kustomization.yaml` and uncomment the LoadBalancer patch.

**Option C: Expose via Ingress**

Create an Ingress resource for the argocd-server service.

### 4. Login

- **Username**: `admin`
- **Password**: (from step 2)

### 5. Change Admin Password

```bash
argocd login localhost:8080
argocd account update-password
```

## Install ArgoCD CLI

### Linux/macOS
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

### Windows
```powershell
choco install argocd-cli
```

Or download from: https://github.com/argoproj/argo-cd/releases

## Deploy Applications

After ArgoCD is running, deploy the root application:

```bash
kubectl apply -f argocd/applications/root-app.yaml
```

This will bootstrap all applications defined in the `apps/` directory using the App of Apps pattern.

## Accessing ArgoCD

### Web UI
- **URL**: https://localhost:8080 (via port-forward)
- **Username**: admin
- **Password**: (from initial secret)

### CLI
```bash
argocd login localhost:8080
argocd app list
argocd app sync <app-name>
```

## Configuration

### Add Git Repository

```bash
argocd repo add https://github.com/your-username/homelab-iac.git
```

### Create Application via CLI

```bash
argocd app create my-app \
  --repo https://github.com/your-username/homelab-iac.git \
  --path apps/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated
```

## Troubleshooting

### Pods Not Starting

Check pod logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Can't Access UI

Verify port-forward:
```bash
kubectl get svc -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Sync Issues

Check application status:
```bash
argocd app get <app-name>
argocd app sync <app-name> --force
```

## Uninstall

```bash
kubectl delete -k argocd/install/
```

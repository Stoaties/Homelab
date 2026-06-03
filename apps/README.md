# Homelab Applications

This directory contains Kubernetes application manifests deployed via ArgoCD using the App of Apps pattern.

## Structure

```
apps/
├── README.md
├── example-app/          # Example application
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── monitoring/           # Monitoring stack (future)
```

## Adding a New Application

### 1. Create Application Directory

```bash
mkdir -p apps/my-app
```

### 2. Add Kubernetes Manifests

Create your manifests in the application directory:

```yaml
# apps/my-app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: nginx:latest
          ports:
            - containerPort: 80
```

### 3. Create ArgoCD Application

```yaml
# apps/my-app/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: homelab
  source:
    repoURL: https://github.com/your-username/homelab-iac.git
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 4. Commit and Push

```bash
git add apps/my-app
git commit -m "Add my-app"
git push
```

ArgoCD will automatically detect and deploy the new application!

## GitOps Workflow

1. **Make Changes**: Edit manifests in `apps/` directory
2. **Commit**: Commit changes to git
3. **Push**: Push to remote repository
4. **Auto-Sync**: ArgoCD automatically syncs changes to cluster

## Manual Sync

If auto-sync is disabled:

```bash
argocd app sync my-app
```

## Common Application Types

### Web Application
- Deployment
- Service
- Ingress (if needed)

### Database
- StatefulSet
- PersistentVolumeClaim
- Service
- Secret (for credentials)

### CronJob
- CronJob
- ConfigMap (for scripts)

## Using Helm Charts

You can also deploy Helm charts via ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
spec:
  project: homelab
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: prometheus
    targetRevision: 15.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Using Kustomize

Organize with Kustomize overlays:

```
apps/my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## Best Practices

1. **Namespace per Application**: Isolate applications in their own namespaces
2. **Resource Limits**: Always set CPU/memory limits
3. **Health Checks**: Define liveness and readiness probes
4. **Secrets Management**: Use sealed-secrets or external-secrets
5. **Versioning**: Pin image tags, avoid `:latest`
6. **Documentation**: Add README.md for each application

## Example Applications to Add

- **Monitoring**: Prometheus + Grafana
- **Logging**: Loki + Promtail
- **Storage**: Longhorn
- **Ingress**: Nginx Ingress Controller
- **Cert Management**: cert-manager
- **Secrets**: External Secrets Operator
- **Service Mesh**: Linkerd or Istio (optional)

## Troubleshooting

### Application Won't Sync

Check application status:
```bash
argocd app get my-app
```

View sync errors:
```bash
kubectl describe application my-app -n argocd
```

### Force Refresh

```bash
argocd app get my-app --refresh
```

### Manual Intervention Required

Some resources may need manual approval:
```bash
argocd app sync my-app --force
```

# Troubleshooting Guide

Common issues and solutions for the homelab infrastructure.

---

## Terraform Issues

### Error: Invalid API Token

**Symptom:**
```
Error: error creating client: error creating new request: error formatting token: error splitting string
```

**Solution:**
- Verify token format: `user@realm!tokenid=secret`
- Ensure token is not expired
- Check Terraform Cloud workspace variable is set correctly
- Token should look like: `root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Error: Cannot Find ISO

**Symptom:**
```
Error: could not find ISO image: local:iso/talos-amd64.iso
```

**Solution:**
```bash
# Verify ISO exists on Proxmox
pvesm list local --content iso

# Upload if missing
cd /var/lib/vz/template/iso
wget https://github.com/siderolabs/talos/releases/latest/download/talos-amd64.iso
```

### Error: Insufficient Permissions

**Symptom:**
```
Error: 403 Forbidden
```

**Solution:**
```bash
# Grant necessary permissions to API token
pveum acl modify / --roles PVEVMAdmin --tokens 'root@pam!terraform'
```

### State Lock Error

**Symptom:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# If sure no other operations running:
terraform force-unlock <lock-id>

# Or login to Terraform Cloud and manually unlock
```

---

## Talos Issues

### Node Not Reachable

**Symptom:**
```
error creating client: failed to dial: context deadline exceeded
```

**Solutions:**

1. **Verify VM is running:**
```bash
# On Proxmox
qm list | grep talos
qm status 101
```

2. **Check network connectivity:**
```bash
ping 10.0.1.101
```

3. **Verify VM has booted:**
- Access Proxmox console for the VM
- Should see Talos OS boot screen

4. **Check IP configuration:**
```bash
# From Proxmox console of VM
talosctl get addresses --insecure
```

### Bootstrap Fails

**Symptom:**
```
error bootstrapping cluster: rpc error: context deadline exceeded
```

**Solutions:**

1. **Verify all control planes are configured:**
```bash
for ip in 10.0.1.101 10.0.1.102 10.0.1.103; do
  echo "Checking $ip..."
  talosctl -n $ip get members --insecure || echo "Failed"
done
```

2. **Check etcd is ready:**
```bash
talosctl -n 10.0.1.101 service etcd status
```

3. **Wait longer - bootstrap can take 5-10 minutes**

4. **Try from different control plane:**
```bash
talosctl bootstrap -n 10.0.1.102
```

### Config Apply Fails

**Symptom:**
```
error applying config: rejected: config validation failed
```

**Solutions:**

1. **Validate config syntax:**
```bash
talosctl validate --config controlplane.yaml --mode metal
```

2. **Check for mismatched secrets:**
- Ensure all nodes use same `secrets.yaml`
- Regenerate if necessary

3. **Use `--insecure` flag:**
```bash
talosctl apply-config --insecure -n 10.0.1.101 --file controlplane.yaml
```

### Can't Get Kubeconfig

**Symptom:**
```
error fetching kubeconfig: connection refused
```

**Solutions:**

1. **Wait for API server:**
```bash
talosctl -n 10.0.1.101 service kube-apiserver status
```

2. **Check bootstrap completed:**
```bash
talosctl -n 10.0.1.101 health
```

3. **Retry kubeconfig retrieval:**
```bash
talosctl kubeconfig -n 10.0.1.101 --force
```

---

## Kubernetes Issues

### Nodes Not Ready

**Symptom:**
```bash
kubectl get nodes
# Shows NotReady status
```

**Solutions:**

1. **Install CNI (if not done):**
```bash
# Cilium
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.15/install/kubernetes/quick-install.yaml

# OR Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

2. **Check kubelet:**
```bash
talosctl -n 10.0.1.101 service kubelet status
```

3. **Check for resource issues:**
```bash
kubectl describe node talos-cp-01
```

### Pods Stuck in Pending

**Symptom:**
```bash
kubectl get pods
# Shows Pending status
```

**Solutions:**

1. **Check node resources:**
```bash
kubectl describe node
kubectl top nodes
```

2. **Check for taints:**
```bash
kubectl describe nodes | grep -i taint
```

3. **Check PVC binding:**
```bash
kubectl get pvc
```

4. **View pod events:**
```bash
kubectl describe pod <pod-name>
```

### CoreDNS Not Working

**Symptom:**
DNS resolution fails inside pods

**Solutions:**

1. **Check CoreDNS pods:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

2. **Check CoreDNS logs:**
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

3. **Verify network policy:**
```bash
kubectl get networkpolicy -A
```

4. **Test DNS:**
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

---

## ArgoCD Issues

### ArgoCD Pods Not Starting

**Symptom:**
ArgoCD pods stuck in Pending or CrashLoopBackOff

**Solutions:**

1. **Check pod status:**
```bash
kubectl get pods -n argocd
kubectl describe pod -n argocd <pod-name>
```

2. **Check for resource constraints:**
```bash
kubectl top pods -n argocd
```

3. **Verify PVCs (if using HA mode):**
```bash
kubectl get pvc -n argocd
```

4. **Check logs:**
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Can't Login to ArgoCD

**Symptom:**
Login fails or password doesn't work

**Solutions:**

1. **Get fresh admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

2. **Reset admin password:**
```bash
# Install ArgoCD CLI first
argocd login localhost:8080
argocd account update-password
```

3. **Check port-forward:**
```bash
# Kill existing port-forward
pkill -f "port-forward.*argocd"

# Start new one
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Application Won't Sync

**Symptom:**
Application stuck in "OutOfSync" or "Unknown" state

**Solutions:**

1. **Check application details:**
```bash
argocd app get <app-name>
```

2. **View sync errors:**
```bash
kubectl describe application <app-name> -n argocd
```

3. **Force refresh:**
```bash
argocd app get <app-name> --refresh
```

4. **Force sync:**
```bash
argocd app sync <app-name> --force
```

5. **Check repository access:**
```bash
argocd repo list
argocd repo get <repo-url>
```

### Repository Access Failed

**Symptom:**
```
Unable to connect to repository
```

**Solutions:**

1. **For public repos - verify URL:**
```bash
# Should be HTTPS, not SSH for public
https://github.com/user/repo.git
```

2. **For private repos - add credentials:**
```bash
argocd repo add https://github.com/user/repo.git \
  --username <username> \
  --password <token>
```

3. **Check network access from cluster:**
```bash
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  wget -O- https://github.com
```

---

## Network Issues

### Inter-Pod Communication Fails

**Solutions:**

1. **Check CNI is installed:**
```bash
kubectl get pods -n kube-system | grep -E 'cilium|flannel|calico'
```

2. **Test pod-to-pod:**
```bash
# Start two test pods
kubectl run test1 --image=nginx
kubectl run test2 --image=busybox --command -- sleep 3600

# Get test1 IP
kubectl get pod test1 -o wide

# Test from test2
kubectl exec test2 -- wget -O- <test1-ip>
```

3. **Check network policies:**
```bash
kubectl get networkpolicy -A
```

### External Access Not Working

**Solutions:**

1. **For NodePort services:**
```bash
# Get service details
kubectl get svc

# Test from external host
curl <node-ip>:<node-port>
```

2. **For LoadBalancer:**
- Requires MetalLB or cloud provider
- Check LoadBalancer implementation

3. **For Ingress:**
- Verify Ingress Controller is installed
- Check Ingress resources

---

## Performance Issues

### High CPU/Memory Usage

**Solutions:**

1. **Check resource usage:**
```bash
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory
```

2. **Set resource limits:**
```yaml
resources:
  limits:
    cpu: "1"
    memory: "1Gi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

3. **Scale down or optimize workloads**

### Disk Space Issues

**Solutions:**

1. **Check Proxmox storage:**
```bash
pvesm status
df -h
```

2. **Clean up unused resources:**
```bash
# Prune Docker images (on Talos)
talosctl -n <node-ip> image list
talosctl -n <node-ip> image prune

# Clean up old pods
kubectl delete pods --field-selector status.phase=Succeeded -A
kubectl delete pods --field-selector status.phase=Failed -A
```

---

## Recovery Procedures

### Restore from Backup

**etcd Snapshot:**
```bash
# Create snapshot
talosctl -n 10.0.1.101 etcd snapshot /tmp/etcd-snapshot.db

# Restore (advanced - requires cluster rebuild)
# See Talos documentation
```

### Recreate Cluster

If cluster is unrecoverable:

1. **Destroy VMs:**
```bash
cd terraform/proxmox
terraform destroy
```

2. **Recreate:**
```bash
terraform apply
```

3. **Bootstrap fresh:**
```bash
cd ../../talos
./scripts/generate-configs.sh  # New secrets!
./scripts/apply-configs.sh
talosctl bootstrap -n 10.0.1.101
```

4. **Restore application state via GitOps**

---

## Getting Help

### Collect Diagnostics

```bash
# Talos
talosctl -n 10.0.1.101 health
talosctl -n 10.0.1.101 logs
talosctl -n 10.0.1.101 dmesg

# Kubernetes
kubectl cluster-info dump

# ArgoCD
argocd app get <app-name>
argocd app logs <app-name>
```

### Useful Resources

- [Talos Docs](https://www.talos.dev/latest/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Proxmox Forum](https://forum.proxmox.com/)

### Community Support

- Talos Slack: [Slack Invite](https://slack.dev.talos-systems.io/)
- Kubernetes Slack: [Slack Invite](https://slack.k8s.io/)
- ArgoCD Slack: [CNCF Slack](https://cloud-native.slack.com/) #argo-cd

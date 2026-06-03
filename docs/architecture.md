# Homelab Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│                    homelab-infrastructure-iac                    │
│  ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Terraform │  │  Talos   │  │ ArgoCD   │  │     Apps     │   │
│  │  Configs  │  │ Configs  │  │ Manifests│  │  Manifests   │   │
│  └───────────┘  └──────────┘  └──────────┘  └──────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ Git Push
                           ▼
         ┌─────────────────────────────────────┐
         │      Terraform Cloud Workspace       │
         │   ┌─────────────────────────────┐   │
         │   │  Workspace Variables:       │   │
         │   │  - proxmox_api_token        │   │
         │   │  - proxmox_endpoint         │   │
         │   └─────────────────────────────┘   │
         └──────────────┬──────────────────────┘
                        │
                        │ Terraform Apply
                        ▼
┌────────────────────────────────────────────────────────────────┐
│                     Proxmox VE Host                             │
│                   IP: 10.0.0.9:8006                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Control Plane Nodes                         │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │  │
│  │  │ talos-cp-01  │ │ talos-cp-02  │ │ talos-cp-03  │    │  │
│  │  │ 10.0.1.101   │ │ 10.0.1.102   │ │ 10.0.1.103   │    │  │
│  │  │              │ │              │ │              │    │  │
│  │  │ 2 CPU        │ │ 2 CPU        │ │ 2 CPU        │    │  │
│  │  │ 4GB RAM      │ │ 4GB RAM      │ │ 4GB RAM      │    │  │
│  │  │ 50GB Disk    │ │ 50GB Disk    │ │ 50GB Disk    │    │  │
│  │  │              │ │              │ │              │    │  │
│  │  │ [etcd]       │ │ [etcd]       │ │ [etcd]       │    │  │
│  │  │ [kube-api]   │ │ [kube-api]   │ │ [kube-api]   │    │  │
│  │  │ [scheduler]  │ │ [scheduler]  │ │ [scheduler]  │    │  │
│  │  │ [controller] │ │ [controller] │ │ [controller] │    │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                  Worker Nodes                            │  │
│  │  ┌─────────────────┐        ┌─────────────────┐         │  │
│  │  │ talos-worker-01 │        │ talos-worker-02 │         │  │
│  │  │ 10.0.1.201      │        │ 10.0.1.202      │         │  │
│  │  │                 │        │                 │         │  │
│  │  │ 4 CPU           │        │ 4 CPU           │         │  │
│  │  │ 8GB RAM         │        │ 8GB RAM         │         │  │
│  │  │ 100GB Disk      │        │ 100GB Disk      │         │  │
│  │  │                 │        │                 │         │  │
│  │  │ [kubelet]       │        │ [kubelet]       │         │  │
│  │  │ [containers]    │        │ [containers]    │         │  │
│  │  └─────────────────┘        └─────────────────┘         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│                    Network: vmbr0                               │
│                    Gateway: 10.0.0.1                            │
└────────────────────────────────────────────────────────────────┘
                           │
                           │ kubectl / talosctl
                           ▼
                 ┌─────────────────────┐
                 │  Admin Workstation   │
                 │                      │
                 │  - kubectl           │
                 │  - talosctl          │
                 │  - terraform         │
                 └─────────────────────┘
```

## Network Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Network: 10.0.0.0/24                   │
│                                                           │
│  ┌────────────┐                                          │
│  │  Gateway   │                                          │
│  │ 10.0.0.1   │                                          │
│  └─────┬──────┘                                          │
│        │                                                  │
│        │                                                  │
│  ┌─────▼─────────────────────────────────────────────┐  │
│  │           Network Switch / Router                  │  │
│  └─────┬──────────────────┬─────────────────┬─────────┘  │
│        │                  │                 │            │
│  ┌─────▼──────┐  ┌────────▼────────┐  ┌────▼─────────┐ │
│  │  Proxmox   │  │  Control Plane  │  │   Workers    │ │
│  │ 10.0.0.9   │  │  10.0.1.101-103 │  │ 10.0.1.201-  │ │
│  │            │  │                 │  │      202     │ │
│  └────────────┘  └─────────────────┘  └──────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Infrastructure Provisioning

```
Developer → Git Push → GitHub → Terraform Cloud → Proxmox API → VMs Created
```

### 2. Talos Bootstrap

```
Admin → talosctl → Control Plane 1 → etcd cluster → Kubernetes API → All Nodes Join
```

### 3. GitOps Deployment

```
Developer → Git Push → GitHub
                         │
                         ▼
ArgoCD (in cluster) → Polls GitHub → Detects Changes → Applies to Kubernetes
```

### 4. Application Traffic

```
External Client → Ingress/LoadBalancer → Service → Pods → Application
```

## Component Responsibilities

### Terraform Layer
- **Purpose**: Infrastructure provisioning
- **Manages**: 
  - VM creation on Proxmox
  - CPU, memory, disk allocation
  - Network configuration
  - Initial VM lifecycle

### Talos Layer
- **Purpose**: Immutable Kubernetes OS
- **Provides**:
  - Minimal attack surface
  - Automated updates
  - etcd cluster
  - Kubernetes components
  - Container runtime

### Kubernetes Layer
- **Purpose**: Container orchestration
- **Manages**:
  - Pod scheduling
  - Service networking
  - Storage orchestration
  - Secret management
  - Resource quotas

### ArgoCD Layer
- **Purpose**: GitOps continuous delivery
- **Handles**:
  - Git repository monitoring
  - Automatic synchronization
  - Application deployment
  - Drift detection & correction
  - Multi-environment management

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Security Layers                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Proxmox Access Control                              │
│     - API Token authentication                          │
│     - TLS encryption                                     │
│     - Role-based access control                         │
│                                                          │
│  2. Talos Security                                       │
│     - Immutable OS (read-only root)                     │
│     - Minimal attack surface                            │
│     - Encrypted communication                           │
│     - Secure boot (UEFI)                                │
│                                                          │
│  3. Kubernetes RBAC                                      │
│     - Service accounts                                   │
│     - Role bindings                                      │
│     - Network policies                                   │
│     - Pod security policies                             │
│                                                          │
│  4. ArgoCD Security                                      │
│     - SSO integration (optional)                         │
│     - Git credentials management                         │
│     - Application-level RBAC                            │
│     - Webhook security                                   │
│                                                          │
│  5. Secrets Management                                   │
│     - Terraform Cloud (encrypted)                        │
│     - Kubernetes Secrets                                 │
│     - External Secrets Operator (optional)              │
│     - Sealed Secrets (optional)                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Storage Layers                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Proxmox Storage                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  local-lvm (thin provisioned)                   │    │
│  │  - VM disks                                     │    │
│  │  - Snapshots                                    │    │
│  └────────────────────────────────────────────────┘    │
│                          │                              │
│                          ▼                              │
│  Talos OS Layer                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  System partition (immutable)                   │    │
│  │  State partition (ephemeral)                    │    │
│  └────────────────────────────────────────────────┘    │
│                          │                              │
│                          ▼                              │
│  Kubernetes Storage                                     │
│  ┌────────────────────────────────────────────────┐    │
│  │  EmptyDir (temporary)                           │    │
│  │  PersistentVolumes (optional)                   │    │
│  │  - Longhorn (future)                            │    │
│  │  - NFS (future)                                 │    │
│  │  - Ceph (future)                                │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Deployment Pipeline

```
┌──────────────┐
│  Developer   │
│  Workstation │
└──────┬───────┘
       │
       │ 1. Write Code
       │
       ▼
┌──────────────────┐
│   Local Testing  │
│   (optional)     │
└──────┬───────────┘
       │
       │ 2. Git Commit & Push
       │
       ▼
┌──────────────────┐
│     GitHub       │
│   Repository     │
└──────┬───────────┘
       │
       │ 3. ArgoCD Polls (every 3 min)
       │
       ▼
┌──────────────────┐
│     ArgoCD       │
│  (in cluster)    │
└──────┬───────────┘
       │
       │ 4. Detect Changes
       │
       ▼
┌──────────────────┐
│  Kubernetes API  │
└──────┬───────────┘
       │
       │ 5. Apply Manifests
       │
       ▼
┌──────────────────┐
│   Application    │
│     Running      │
└──────────────────┘
```

## High Availability Considerations

### Current Setup
- ✅ 3 control plane nodes (etcd quorum)
- ✅ 2 worker nodes (workload distribution)
- ⚠️ Single Proxmox host (SPOF)

### Future Enhancements

**For Production HA:**
```
1. Proxmox Cluster (3+ nodes)
   - Shared storage (Ceph)
   - HA VM management
   - Live migration

2. Load Balancer for Control Plane
   - VIP: 10.0.1.100
   - Round-robin to CP nodes

3. Storage HA
   - Longhorn (distributed storage)
   - Replication factor: 3

4. Application HA
   - Multiple replicas
   - Pod anti-affinity
   - Resource limits
```

## Monitoring & Observability (Future)

```
┌─────────────────────────────────────────────────┐
│         Monitoring Stack (To Add)                │
├─────────────────────────────────────────────────┤
│                                                  │
│  Metrics: Prometheus + Grafana                  │
│  Logs: Loki + Promtail                          │
│  Traces: Tempo (optional)                       │
│  Alerts: AlertManager                           │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Disaster Recovery

### Backup Strategy
```
1. Infrastructure Code (Git)
   - Terraform configs
   - Talos configs
   - ArgoCD manifests

2. Cluster State
   - etcd snapshots (automated)
   - PV backups (Velero)

3. Proxmox VMs
   - VM snapshots
   - vzdump backups
```

### Recovery Procedure
```
1. Restore Proxmox VMs (if needed)
2. Re-apply Terraform (recreate VMs)
3. Bootstrap Talos cluster
4. Restore etcd snapshot
5. Deploy ArgoCD
6. GitOps restores applications
```

## Cost Analysis

| Component | Cost |
|-----------|------|
| Hardware (Proxmox host) | One-time: $$$$ |
| Terraform Cloud | Free (up to 500 resources/month) |
| GitHub | Free (public repos) |
| Software (Talos, K8s, ArgoCD) | Free (open source) |
| Electricity | ~$5-20/month |
| **Total Monthly** | **~$5-20** |

## Scalability

### Current Capacity
- **Pods**: ~110 per node = 550 total
- **Services**: Unlimited (software limit)
- **Namespaces**: Unlimited
- **PVs**: Depends on storage

### Scaling Options

**Vertical Scaling:**
- Increase VM CPU/RAM
- Add more disk space

**Horizontal Scaling:**
- Add more worker VMs
- Terraform makes this trivial

**Cluster Scaling:**
- Deploy multiple clusters
- Federate with Submariner (advanced)

## Technology Stack Summary

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Hypervisor | Proxmox VE | Latest | VM management |
| IaC | Terraform | 1.5+ | Infrastructure provisioning |
| OS | Talos Linux | 1.7+ | Immutable Kubernetes OS |
| Orchestration | Kubernetes | 1.30+ | Container platform |
| GitOps | ArgoCD | 2.11+ | CD pipeline |
| State Management | Terraform Cloud | - | Remote state & secrets |
| VCS | GitHub | - | Source control |

---

**Last Updated**: 2026-06-02  
**Architecture Version**: 1.0

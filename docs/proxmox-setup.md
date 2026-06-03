# Proxmox Setup Details

This document covers Proxmox-specific configuration for the homelab.

## Network Configuration

### Bridge Configuration

The cluster uses the default Proxmox bridge `vmbr0`:

```
# /etc/network/interfaces (on Proxmox host)
auto vmbr0
iface vmbr0 inet static
    address 10.0.0.9/24
    gateway 10.0.0.1
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0
```

### IP Allocation

| Purpose | IP Range | Count |
|---------|----------|-------|
| Proxmox Host | 10.0.0.9 | 1 |
| Gateway | 10.0.0.1 | 1 |
| Control Planes | 10.0.1.101 - 10.0.1.103 | 3 |
| Workers | 10.0.1.201 - 10.0.1.202 | 2 |
| Future Expansion | 10.0.1.104 - 10.0.1.199 | Available |
| Future Workers | 10.0.1.203 - 10.0.1.299 | Available |

## Storage Configuration

### Local Storage

Default storage pools:

- **local**: ISO images, CT templates, backups
- **local-lvm**: VM disks (thin provisioned)

### Recommended Storage Layout

For production, consider:

- **SSD/NVMe**: VM system disks (fast I/O)
- **HDD/RAID**: Data volumes (large capacity)
- **NFS/Ceph**: Shared storage (HA)

## VM Specifications

### Control Plane Nodes

| Resource | Specification |
|----------|--------------|
| CPU | 2 cores (host type) |
| RAM | 4 GB |
| Disk | 50 GB |
| Network | VirtIO, vmbr0 |
| BIOS | OVMF (UEFI) |

### Worker Nodes

| Resource | Specification |
|----------|--------------|
| CPU | 4 cores (host type) |
| RAM | 8 GB |
| Disk | 100 GB |
| Network | VirtIO, vmbr0 |
| BIOS | OVMF (UEFI) |

## API Token Setup

### Creating API Token

```bash
# Via Proxmox Web UI:
# 1. Datacenter → Permissions → API Tokens
# 2. Add → Select user, enter Token ID
# 3. Uncheck "Privilege Separation"
# 4. Copy generated token

# Via CLI (on Proxmox host):
pveum user token add root@pam terraform --privsep 0
```

### Token Format

```
user@realm!tokenid=secret
# Example:
root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Required Permissions

For Terraform to manage VMs, the token needs:

- VM.Allocate
- VM.Config.Disk
- VM.Config.CPU
- VM.Config.Memory
- VM.Config.Network
- VM.Config.Options
- VM.Monitor
- VM.PowerMgmt
- Datastore.AllocateSpace

Grant via:
```bash
pveum acl modify / --roles PVEVMAdmin --tokens 'root@pam!terraform'
```

## ISO Management

### Upload Talos ISO

**Via Web UI:**
1. Select node → local → ISO Images
2. Click "Upload"
3. Select `talos-amd64.iso`

**Via CLI (from Proxmox host):**
```bash
cd /var/lib/vz/template/iso
wget https://github.com/siderolabs/talos/releases/download/v1.7.0/talos-amd64.iso
```

**Via Remote Upload:**
```bash
scp talos-amd64.iso root@10.0.0.9:/var/lib/vz/template/iso/
```

### Verify ISO

```bash
pvesm list local --content iso
```

## Cluster Configuration

### Multi-Node Setup

If using multiple Proxmox nodes:

1. Form cluster:
```bash
# On first node:
pvecm create homelab-cluster

# On additional nodes:
pvecm add 10.0.0.9
```

2. Configure shared storage (Ceph, NFS, etc.)

3. Update Terraform to distribute VMs:
```hcl
variable "proxmox_nodes" {
  type = list(string)
  default = ["pve1", "pve2", "pve3"]
}
```

### High Availability

For HA setup:
1. Enable HA in Proxmox
2. Configure fencing
3. Set VM HA policy:
```bash
ha-manager add vm:101 --state started --group ha-group-1
```

## Backup Strategy

### Manual Backup

```bash
vzdump 101 --mode snapshot --compress zstd --storage local
```

### Automated Backup

Configure via Web UI:
1. Datacenter → Backup
2. Add schedule
3. Select VMs
4. Choose storage
5. Set retention policy

### Talos-Specific Considerations

Talos OS is immutable, but backup:
- **etcd data** (Kubernetes state)
- **Talos configurations** (in git)
- **Application data** (PVs)

## Monitoring Proxmox

### Check Resource Usage

```bash
pvesh get /nodes/pve/status
pvesh get /cluster/resources
```

### Monitor VMs

```bash
pvesh get /cluster/resources --type vm
```

### View VM Status

```bash
qm list
qm status 101
```

## Firewall Configuration

### Enable Proxmox Firewall

```bash
# Enable at datacenter level
pvesh set /cluster/firewall/options --enable 1

# Enable for specific VM
pvesh set /nodes/pve/qemu/101/firewall/options --enable 1
```

### Allow Kubernetes Ports

```
# Control Plane
6443/tcp  - Kubernetes API
2379-2380 - etcd
10250     - kubelet
10251     - kube-scheduler
10252     - kube-controller-manager

# Workers
10250     - kubelet
30000-32767 - NodePort services

# Talos
50000/tcp - Talos API
```

## Troubleshooting

### VM Won't Start

```bash
# Check VM config
qm config 101

# View VM logs
journalctl -u pve-firewall
tail -f /var/log/pve/tasks/*.log
```

### Network Issues

```bash
# Test connectivity from Proxmox host
ping 10.0.1.101

# Check bridge status
brctl show vmbr0

# Verify VM network config
qm config 101 | grep net
```

### Storage Issues

```bash
# Check storage status
pvesm status

# Check available space
df -h

# Thin pool usage (LVM)
lvs
```

### Performance Tuning

For better VM performance:

```bash
# Enable CPU host passthrough (already set in Terraform)
# Enable I/O thread (already set in Terraform)

# Adjust VM priority
qm set 101 --shares 2000

# Pin vCPUs to physical cores (advanced)
qm set 101 --affinity 0,1
```

## Useful Commands

```bash
# List all VMs
qm list

# Start VM
qm start 101

# Stop VM
qm stop 101

# Reset VM
qm reset 101

# Access VM console
qm terminal 101

# Get VM IP
qm agent 101 network-get-interfaces

# Clone VM
qm clone 101 201 --name new-vm

# Delete VM
qm destroy 101
```

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox API](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

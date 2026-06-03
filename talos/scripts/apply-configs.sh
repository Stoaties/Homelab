#!/bin/bash
# Apply Talos configurations to nodes

set -e

# Control plane IPs
CONTROL_PLANE_IPS=("10.0.1.101" "10.0.1.102" "10.0.1.103")

# Worker IPs
WORKER_IPS=("10.0.1.201" "10.0.1.202")

echo "Applying Talos configurations to cluster nodes"
echo "=============================================="
echo ""

# Apply to control plane nodes
echo "Applying configurations to control plane nodes..."
for i in "${!CONTROL_PLANE_IPS[@]}"; do
    IP="${CONTROL_PLANE_IPS[$i]}"
    NODE_NUM=$((i + 1))
    echo "  → Control Plane $NODE_NUM ($IP)"
    
    # Wait for node to be available
    echo "    Waiting for node to be ready..."
    until talosctl -n $IP disks --insecure &>/dev/null; do
        sleep 2
    done
    
    # Apply config
    talosctl apply-config --insecure \
        --nodes $IP \
        --file controlplane.yaml
    
    echo "    ✅ Configuration applied"
done

echo ""

# Apply to worker nodes
echo "Applying configurations to worker nodes..."
for i in "${!WORKER_IPS[@]}"; do
    IP="${WORKER_IPS[$i]}"
    NODE_NUM=$((i + 1))
    echo "  → Worker $NODE_NUM ($IP)"
    
    # Wait for node to be available
    echo "    Waiting for node to be ready..."
    until talosctl -n $IP disks --insecure &>/dev/null; do
        sleep 2
    done
    
    # Apply config
    talosctl apply-config --insecure \
        --nodes $IP \
        --file worker.yaml
    
    echo "    ✅ Configuration applied"
done

echo ""
echo "✅ All configurations applied!"
echo ""
echo "Next steps:"
echo "1. Bootstrap the first control plane:"
echo "   talosctl bootstrap -n ${CONTROL_PLANE_IPS[0]}"
echo ""
echo "2. Wait for cluster to be ready (this may take a few minutes)"
echo ""
echo "3. Get kubeconfig:"
echo "   talosctl kubeconfig -n ${CONTROL_PLANE_IPS[0]}"
echo ""
echo "4. Verify cluster:"
echo "   kubectl get nodes"

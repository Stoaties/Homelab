#!/bin/bash
# Generate Talos configuration files for the cluster

set -e

# Configuration
CLUSTER_NAME="homelab"
CLUSTER_ENDPOINT="https://10.0.1.101:6443"
KUBERNETES_VERSION="1.30.0"

# Control plane IPs
CONTROL_PLANE_IPS=("10.0.1.101" "10.0.1.102" "10.0.1.103")

# Worker IPs
WORKER_IPS=("10.0.1.201" "10.0.1.202")

echo "Generating Talos configurations for cluster: $CLUSTER_NAME"
echo "Cluster endpoint: $CLUSTER_ENDPOINT"
echo ""

# Generate secrets if they don't exist
if [ ! -f "secrets.yaml" ]; then
    echo "Generating cluster secrets..."
    talosctl gen secrets -o secrets.yaml
fi

# Generate base configurations
echo "Generating base configurations..."
talosctl gen config $CLUSTER_NAME $CLUSTER_ENDPOINT \
    --with-secrets secrets.yaml \
    --kubernetes-version $KUBERNETES_VERSION \
    --install-disk /dev/sda

echo ""
echo "✅ Base configurations generated!"
echo ""
echo "Generated files:"
echo "  - controlplane.yaml (template)"
echo "  - worker.yaml (template)"
echo "  - talosconfig"
echo ""
echo "Next steps:"
echo "1. Review the generated configurations"
echo "2. Apply configurations to nodes with ./apply-configs.sh"
echo "3. Bootstrap the cluster with: talosctl bootstrap -n 10.0.1.101"
echo "4. Get kubeconfig with: talosctl kubeconfig -n 10.0.1.101"

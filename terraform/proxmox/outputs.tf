output "control_plane_names" {
  description = "Hostnames of control plane nodes"
  value       = [for i in range(var.control_plane_count) : "talos-cp-${format("%02d", i + 1)}"]
}

output "worker_names" {
  description = "Hostnames of worker nodes"
  value       = [for i in range(var.worker_count) : "talos-worker-${format("%02d", i + 1)}"]
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint (update cluster_endpoint variable after first boot)"
  value       = var.cluster_endpoint
}

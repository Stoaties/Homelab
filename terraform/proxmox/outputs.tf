output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value       = var.control_plane_ips
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = var.worker_ips
}

output "control_plane_names" {
  description = "Hostnames of control plane nodes"
  value       = [for i in range(var.control_plane_count) : "talos-cp-${format("%02d", i + 1)}"]
}

output "worker_names" {
  description = "Hostnames of worker nodes"
  value       = [for i in range(var.worker_count) : "talos-worker-${format("%02d", i + 1)}"]
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint (first control plane)"
  value       = "https://${var.control_plane_ips[0]}:6443"
}

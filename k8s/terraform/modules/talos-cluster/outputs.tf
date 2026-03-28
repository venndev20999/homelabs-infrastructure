output "talosconfig" {
  description = "The generated talosconfig"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "The generated kubeconfig"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

# ── Exposed for Helm / Kubernetes providers ──────────────────────────────────
output "kubeconfig_host" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  sensitive = true
}

output "kubeconfig_client_cert" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate
  sensitive = true
}

output "kubeconfig_client_key" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key
  sensitive = true
}

output "kubeconfig_ca_cert" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate
  sensitive = true
}

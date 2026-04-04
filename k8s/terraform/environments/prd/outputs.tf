output "talosconfig" {
  description = "The talosconfig file content. Write it to ~/.talos/config using `terraform output -raw talosconfig > ~/.talos/config`"
  value       = module.talos_cluster.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "The Kubernetes config file content. Write it to ~/.kube/config using `terraform output -raw kubeconfig > ~/.kube/config`"
  value       = module.talos_cluster.kubeconfig
  sensitive   = true
}

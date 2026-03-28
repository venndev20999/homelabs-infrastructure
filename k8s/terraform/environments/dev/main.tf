# environments/dev/main.tf
# Installs Talos cluster onto VMs already provisioned by Ansible.
# The Talos provider connects directly to each node's IP via the Talos API (port 50000)
# using machine secrets it generates itself — no SSH, no password needed.
#
# Auth flow:
#   1. terraform apply generates `talos_machine_secrets` (PKI certs + cluster token)
#   2. Applies machine config to each node via Talos API (mTLS, port 50000)
#   3. Bootstraps etcd on first control plane
#   4. Retrieves kubeconfig from the cluster
#
# Prerequisites:
#   - VMs booted from Talos ISO (Maintenance mode, reachable via libvirt NAT)
#   - Run from localserver OR with SSH tunnel: ssh -L 50000:192.168.122.110:50000 localserver
#   - terraform init (downloads siderolabs/talos provider)

# terraform {
#   required_providers {
#     talos = {
#       source  = "siderolabs/talos"
#       version = ">= 0.6.0"
#     }
#   }

#   # Optional: store state remotely so team can share
#   # backend "s3" {
#   #   bucket = "finance-stock-tfstate"
#   #   key    = "k8s/dev/terraform.tfstate"
#   #   region = "ap-southeast-1"
#   # }
# }

module "talos_cluster" {
  source = "../../modules/talos-cluster"

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  controlplane_ips = var.controlplane_ips
  worker_ips       = var.worker_ips
  talos_version    = var.talos_version
}

# # ── Outputs ────────────────────────────────────────────────────────────────────
# output "talosconfig" {
#   description = "Save to ~/.talos/config: terraform output -raw talosconfig > ~/.talos/config"
#   value       = module.talos_cluster.talosconfig
#   sensitive   = true
# }

# output "kubeconfig" {
#   description = "Save to ~/.kube/config: terraform output -raw kubeconfig > ~/.kube/config"
#   value       = module.talos_cluster.kubeconfig
#   sensitive   = true
# }

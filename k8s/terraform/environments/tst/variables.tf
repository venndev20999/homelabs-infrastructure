# environments/dev/variables.tf
variable "cluster_name" {
  type        = string
  description = "Talos cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "Kubernetes API server endpoint (https://<control-plane-ip>:6443)"
}

variable "controlplane_ips" {
  type        = list(string)
  description = "IP addresses of control plane nodes"
}

variable "worker_ips" {
  type        = list(string)
  description = "IP addresses of worker nodes"
  default     = []
}

variable "talos_version" {
  type        = string
  description = "Talos OS version"
  default     = "v1.7.0"
}

# ── Cloudflare Configuration ──────────────────────────────────────────────────
variable "cloudflare_token" {
  type        = string
  description = "Cloudflare API Token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "cloudflare_tunnel_token" {
  type        = string
  description = "Cloudflare Tunnel Token"
  sensitive   = true
}

variable "env_prefix" {
  type        = string
  description = "Environment prefix for hostnames"
  default     = "dev"
}

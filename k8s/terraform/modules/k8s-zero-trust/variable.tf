variable "tailscale_auth_key" {
  type        = string
  description = "Tailscale Auth Key (ephemeral/one-time or reusable)"
  sensitive   = true
}

variable "advertise_routes" {
  type        = list(string)
  description = "Subnet routes to advertise to the Tailnet"
  default     = ["192.168.122.0/24", "10.244.0.0/16", "10.96.0.0/12"]
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy Tailscale"
  default     = "vpn"
}

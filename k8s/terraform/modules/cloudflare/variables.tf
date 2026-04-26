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

variable "tunnel_id" {
  type        = string
  description = "Existing Cloudflare Tunnel ID"
}

variable "domain" {
  type        = string
  description = "Base domain (e.g., vennpham.work)"
}

# ── Platform Configuration ───────────────────────────────────────────────────

variable "gateway_ip" {
  type        = string
  description = "Default Gateway IP for k8s traffic"
  default     = ""
}

variable "ingress_rules" {
  type = list(object({
    hostname = string
    service  = string
    path     = optional(string)
  }))
  description = "List of ingress rules for the tunnel (VMs, services, etc.)"
  default     = []
}

variable "dns_records" {
  type = map(object({
    type    = string
    value   = string
    proxied = optional(bool, true)
  }))
  description = "Additional DNS records to manage"
  default     = {}
}

variable "enable_k8s_agent" {
  type        = bool
  description = "Whether to deploy the cloudflared agent to Kubernetes"
  default     = false
}

variable "manage_tunnel_config" {
  type        = bool
  description = "Whether to manage the tunnel's ingress rules via Terraform"
  default     = true
}

variable "k8s_namespace" {
  type        = string
  description = "Namespace for the cloudflared agent"
  default     = "kube-system"
}

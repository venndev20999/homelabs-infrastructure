variable "cloudflare_token" {
  type        = string
  description = "Cloudflare API Token with DNS and Tunnel permissions"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for vennpham.work"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "tunnel_id" {
  type        = string
  description = "Existing Cloudflare Tunnel ID"
  default     = "aa3d250f-e275-4674-a1a3-9bcfe666286a"
}

variable "tunnel_secret" {
  type        = string
  description = "Cloudflare Tunnel Secret (if creating new) or Token"
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "Base domain (e.g., vennpham.work)"
  default     = "vennpham.work"
}

variable "gateway_ip" {
  type        = string
  description = "Shared Gateway IP to route traffic to"
  default     = "192.168.122.201"
}

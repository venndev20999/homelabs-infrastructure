variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file for the cluster"
  default     = "../stg/output/kubeconfig"
}

variable "argocd_admin_password" {
  type        = string
  description = "BCrypt hashed admin password for ArgoCD"
  default     = ""
  sensitive   = true
}

variable "minio_endpoint" {
  type        = string
  description = "MinIO server endpoint"
  default     = "192.168.1.223:9000"
}

variable "minio_user" {
  type        = string
  description = "MinIO username"
  default     = "vennpham"
}

variable "minio_password" {
  type        = string
  description = "MinIO password"
  default     = "dnquynh#123"
  sensitive   = true
}

variable "tailscale_auth_key" {
  type        = string
  description = "Tailscale Auth Key for subnet router registration"
  sensitive   = true
}

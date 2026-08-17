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

variable "github_client_id" {
  type        = string
  description = "GitHub OAuth Application Client ID"
  default     = ""
}

variable "github_client_secret" {
  type        = string
  description = "GitHub OAuth Application Client Secret"
  default     = ""
  sensitive   = true
}

variable "github_admin_user" {
  type        = string
  description = "GitHub username or email to grant admin privileges in ArgoCD"
  default     = "khoapham.dev20999@gmail.com"
}

variable "grafana_github_client_id" {
  type        = string
  description = "GitHub OAuth Application Client ID for Grafana"
  default     = ""
}

variable "grafana_github_client_secret" {
  type        = string
  description = "GitHub OAuth Application Client Secret for Grafana"
  default     = ""
  sensitive   = true
}

variable "grafana_github_admin_email" {
  type        = string
  description = "GitHub email address authorized to log in as administrator in Grafana"
  default     = "khoapham.dev20999@gmail.com"
}

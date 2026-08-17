variable "argocd_version" {
  type        = string
  description = "ArgoCD Helm chart version"
  default     = "7.3.11"
}

variable "argocd_admin_password" {
  type        = string
  description = "Optional BCrypt hashed admin password for ArgoCD"
  default     = ""
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file for the cluster"
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

variable "admin_users" {
  type        = list(string)
  description = "List of GitHub emails to grant admin privileges in ArgoCD"
  default     = []
}

variable "developer_users" {
  type        = list(string)
  description = "List of GitHub emails to grant read-only view privileges in ArgoCD"
  default     = []
}

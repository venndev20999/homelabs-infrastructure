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

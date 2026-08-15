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

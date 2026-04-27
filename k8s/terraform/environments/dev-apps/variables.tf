variable "argocd_admin_password" {
  type        = string
  description = "ArgoCD admin password"
  sensitive   = true
}

variable "repo_url" {
  type        = string
  description = "Git repository URL for application manifests"
  default     = "https://github.com/venndev20999/homelabs-infrastructure.git"
}

variable "target_revision" {
  type        = string
  description = "Git branch or tag to track"
  default     = "ft/dev"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token for private repositories"
  sensitive   = true
}

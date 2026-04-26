variable "namespace" {
  type        = string
  description = "The namespace to deploy ArgoCD into."
  default     = "argocd"
}

variable "chart_version" {
  type        = string
  description = "The version of the ArgoCD Helm chart to use."
  default     = "7.3.11" # Use a recent stable version
}

variable "ingress_enabled" {
  type        = bool
  description = "Whether to enable ingress for ArgoCD."
  default     = false
}

variable "hostnames" {
  type        = list(string)
  description = "List of hostnames for ArgoCD ingress"
  default     = ["argocd.vennpham.work", "argocd.vennpham.local"]
}

variable "redis_db" {
  type        = number
  description = "Redis database index to use (e.g., 0 for dev, 1 for test)"
  default     = 0
}

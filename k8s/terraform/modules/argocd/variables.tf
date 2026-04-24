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

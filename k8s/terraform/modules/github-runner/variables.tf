variable "namespace" {
  type        = string
  description = "Namespace to deploy GitHub runner pods"
  default     = "arc-runners"
}

variable "controller_namespace" {
  type        = string
  description = "Namespace to deploy Actions Runner Controller"
  default     = "arc-systems"
}

variable "github_url" {
  type        = string
  description = "GitHub Repository or Org URL to register the runner"
  default     = "https://github.com/venndev20999/finance-stock"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token (PAT) for runner registration"
  sensitive   = true
}

variable "runner_node_name" {
  type        = string
  description = "The hostname of the Talos node to target"
  default     = "talos-vm-worker-4-stg"
}

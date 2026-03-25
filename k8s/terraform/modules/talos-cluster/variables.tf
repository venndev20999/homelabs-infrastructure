variable "cluster_name" {
  description = "The name of the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server (e.g., https://10.0.0.10:6443 or a load balancer IP)"
  type        = string
}

variable "controlplane_ips" {
  description = "List of IP addresses for the controlplane nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "List of IP addresses for the worker nodes"
  type        = list(string)
  default     = []
}

variable "talos_version" {
  description = "The Talos version to use"
  type        = string
  default     = "v1.7.0"
}

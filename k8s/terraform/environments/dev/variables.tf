# environments/dev/variables.tf
variable "cluster_name" {
  type        = string
  description = "Talos cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "Kubernetes API server endpoint (https://<control-plane-ip>:6443)"
}

variable "controlplane_ips" {
  type        = list(string)
  description = "IP addresses of control plane nodes"
}

variable "worker_ips" {
  type        = list(string)
  description = "IP addresses of worker nodes"
  default     = []
}

variable "talos_version" {
  type        = string
  description = "Talos OS version"
  default     = "v1.7.0"
}

variable "cni" {
  type        = string
  description = "The CNI plugin to deploy (cilium or calico)"
  default     = "calico"
}

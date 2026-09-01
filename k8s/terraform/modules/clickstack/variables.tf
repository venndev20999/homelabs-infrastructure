variable "namespace" {
  type        = string
  description = "Kubernetes namespace for ClickStack"
  default     = "clickstack"
}

variable "clickhouse_node" {
  type        = string
  description = "Worker node hostname to pin the ClickHouse pod onto"
  default     = "talos-vm-worker-4-stg"
}

variable "clickhouse_pvc_size" {
  type        = string
  description = "Size of the Persistent Volume Claim for ClickHouse data"
  default     = "50Gi"
}

variable "storage_class_name" {
  type        = string
  description = "Kubernetes StorageClass name for PVCs"
  default     = "local-path"
}

variable "app_user_password" {
  type        = string
  description = "Password for ClickHouse HyperDX application user"
  sensitive   = true
  default     = "HyperDXSecurePassword2026!"
}

variable "otel_user_password" {
  type        = string
  description = "Password for ClickHouse OpenTelemetry collector user"
  sensitive   = true
  default     = "OTelCollectorSecurePass2026!"
}

variable "hyperdx_api_key" {
  type        = string
  description = "API Key for HyperDX ingestion and UI access"
  sensitive   = true
  default     = "c11c57ac-0001-4000-8000-0123456789ab"
}

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

variable "minio_endpoint" {
  type        = string
  description = "MinIO server endpoint"
  default     = "192.168.1.223:9000"
}

variable "minio_user" {
  type        = string
  description = "MinIO username"
  default     = "vennpham"
}

variable "minio_password" {
  type        = string
  description = "MinIO password"
  default     = "dnquynh#123"
  sensitive   = true
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

variable "grafana_github_client_id" {
  type        = string
  description = "GitHub OAuth Application Client ID for Grafana"
  default     = ""
}

variable "grafana_github_client_secret" {
  type        = string
  description = "GitHub OAuth Application Client Secret for Grafana"
  default     = ""
  sensitive   = true
}

variable "tailscale_auth_key" {
  type        = string
  description = "Tailscale Auth Key for subnet router registration"
  sensitive   = true
}

# variable "github_runner_token" {
#   type        = string
#   description = "GitHub Personal Access Token (PAT) for Runner registration"
#   sensitive   = true
# }

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token (PAT) for ArgoCD and general Git Access"
  sensitive   = true
}

# ── Observability & Monitoring Toggles ─────────────────────────────────────────
variable "enable_k8s_monitoring" {
  type        = bool
  description = "Toggle to enable/disable LGTM stack (Loki, Grafana, Tempo, Prometheus, Alloy)"
  default     = false
}

variable "enable_clickstack" {
  type        = bool
  description = "Toggle to enable/disable ClickHouse & ClickStack observability stack"
  default     = true
}

# ── ClickStack Sensitive Credentials (loaded via SOPS secrets.dec.yaml) ────────
variable "clickstack_app_password" {
  type        = string
  description = "Password for ClickHouse HyperDX application user"
  sensitive   = true
  default     = "HyperDXSecurePassword2026!"
}

variable "clickstack_otel_password" {
  type        = string
  description = "Password for ClickHouse OpenTelemetry collector user"
  sensitive   = true
  default     = "OTelCollectorSecurePass2026!"
}

variable "clickstack_hyperdx_api_key" {
  type        = string
  description = "API Key for HyperDX ingestion and UI access"
  sensitive   = true
  default     = "c11c57ac-0001-4000-8000-0123456789ab"
}

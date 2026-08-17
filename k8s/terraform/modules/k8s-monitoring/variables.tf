variable "minio_endpoint" {
  type        = string
  description = "MinIO server endpoint (IP:Port)"
  default     = "192.168.1.223:9000"
}

variable "minio_user" {
  type        = string
  description = "MinIO username/access key"
  default     = "vennpham"
}

variable "minio_password" {
  type        = string
  description = "MinIO password/secret key"
  default     = "dnquynh#123"
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

variable "grafana_github_admin_email" {
  type        = string
  description = "GitHub email address authorized to log in as administrator in Grafana"
  default     = "khoapham.dev20999@gmail.com"
}

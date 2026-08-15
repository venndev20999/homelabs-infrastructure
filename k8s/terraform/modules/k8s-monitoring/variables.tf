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

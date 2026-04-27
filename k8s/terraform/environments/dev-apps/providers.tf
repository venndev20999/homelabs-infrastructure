terraform {
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "argocd" {
  server_addr = "argocd.vennpham.local:80"
  username    = "admin"
  password    = var.argocd_admin_password
  insecure    = true
  plain_text  = true
}

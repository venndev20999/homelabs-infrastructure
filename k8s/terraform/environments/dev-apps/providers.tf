terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6.0"
    }
  }
}

provider "argocd" {
  server_addr = "argocd.vennpham.work:443"
  username    = "admin"
  password    = var.argocd_admin_password
}

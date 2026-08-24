# Ensure the staging namespace exists and is managed by Terraform
resource "kubernetes_namespace_v1" "staging" {
  metadata {
    name = "staging"
  }
}

# Ensure the production namespace exists and is managed by Terraform
resource "kubernetes_namespace_v1" "production" {
  metadata {
    name = "production"
  }
}

# Auto-import staging namespace if it already exists in the cluster
import {
  to = kubernetes_namespace_v1.staging
  id = "staging"
}


# Docker registry pull secret in staging namespace
resource "kubernetes_secret_v1" "ghcr_pull_secret_staging" {
  depends_on = [
    kubernetes_namespace_v1.staging
  ]

  metadata {
    name      = "ghcr-pull-secret"
    namespace = kubernetes_namespace_v1.staging.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = "venndev20999"
          password = var.github_token
          email    = "khoapham.dev20999@gmail.com"
          auth     = base64encode("venndev20999:${var.github_token}")
        }
      }
    })
  }
}

# Docker registry pull secret in production namespace
resource "kubernetes_secret_v1" "ghcr_pull_secret_production" {
  depends_on = [
    kubernetes_namespace_v1.production
  ]

  metadata {
    name      = "ghcr-pull-secret"
    namespace = kubernetes_namespace_v1.production.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = "venndev20999"
          password = var.github_token
          email    = "khoapham.dev20999@gmail.com"
          auth     = base64encode("venndev20999:${var.github_token}")
        }
      }
    })
  }
}

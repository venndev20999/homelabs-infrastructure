resource "argocd_application" "root_app" {
  metadata {
    name      = "root-app"
    namespace = "argocd"
    labels = {
      managed-by = "terraform"
      type       = "root"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = var.repo_url
      target_revision = var.target_revision
      path            = "infrastructure/k8s/argocd" # This folder contains your ApplicationSet manifests
      directory {
        recurse = true
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "argocd"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      retry {
        limit = "5"
        backoff {
          duration     = "30s"
          max_duration = "3m"
          factor       = "2"
        }
      }
    }
  }
}

# This registers your "Test Cluster" into the "Dev ArgoCD"
resource "kubernetes_secret" "test_cluster" {
  metadata {
    name      = "test-cluster-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "environment"                    = "test" # Label for discovery
    }
  }

  data = {
    name   = "test-cluster"
    server = "https://<TEST_CLUSTER_API_ENDPOINT>:6443"
    config = jsonencode({
      bearerToken = "<SERVICE_ACCOUNT_TOKEN_FROM_TEST_CLUSTER>"
      tlsClientConfig = {
        insecure = false
        caData   = "<BASE64_CA_CERT_FROM_TEST_CLUSTER>"
      }
    })
  }
}

# 🚀 Credential Template for all repositories in the organization
resource "kubernetes_secret" "github_repo_creds" {
  metadata {
    name      = "github-repo-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    url      = "https://github.com/venndev20999"
    username = "venndev20999"
    password = var.github_token
  }
}

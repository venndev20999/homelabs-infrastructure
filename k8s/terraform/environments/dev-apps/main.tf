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
      path            = "k8s/apps/dev" # This folder will contain your other App manifests
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
        prune     = true
        self_heal = true
        allow_empty = true
      }
      retry {
        limit   = "5"
        backoff {
          duration     = "30s"
          max_duration = "3m"
          factor       = "2"
        }
      }
    }
  }
}

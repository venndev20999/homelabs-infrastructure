# Create the organization-wide repository credential template in ArgoCD namespace.
# This matches any private repository under github.com/venndev20999/* automatically.
resource "kubernetes_secret_v1" "argocd_github_creds" {
  depends_on = [
    module.k8s_add_ons
  ]

  metadata {
    name      = "github-org-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = "https://github.com/venndev20999"
    username = "venndev20999"
    password = var.github_token
  }

  type = "Opaque"
}

# Create the root "App-of-Apps" Bootstrap Application.
# It monitors your path 'k8s/argocd-apps/apps' for any individual application manifests.
resource "kubernetes_manifest" "root_bootstrap" {
  depends_on = [
    module.k8s_add_ons,
    kubernetes_secret_v1.argocd_github_creds
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-bootstrap"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/venndev20999/homelabs-infrastructure.git"
        targetRevision = "dev"
        path           = "k8s/argocd-apps/apps"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}

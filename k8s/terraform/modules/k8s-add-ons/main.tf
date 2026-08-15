# Create namespace for ArgoCD
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Deploy ArgoCD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false

  values = var.argocd_admin_password != "" ? [
    yamlencode({
      configs = {
        secret = {
          # Hashed password for admin user
          argocdAdminPassword = var.argocd_admin_password
        }
      }
    })
  ] : []
}

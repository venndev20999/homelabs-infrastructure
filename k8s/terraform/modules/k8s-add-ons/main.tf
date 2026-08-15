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

# Deploy Envoy Gateway (Gateway API controller) via OCI Helm chart
resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = "v1.1.0"
  namespace        = "envoy-gateway-system"
  create_namespace = true
}

# Deploy MetalLB via Helm
resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = "0.14.8"
  namespace        = "metallb-system"
  create_namespace = true
}

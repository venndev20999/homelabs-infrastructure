# Create namespace for ArgoCD
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Deploy ArgoCD via Helm
resource "helm_release" "argocd" {
  depends_on = [
    kubernetes_namespace_v1.argocd
  ]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      configs = merge(
        {
          params = {
            "server.insecure" = true
          }
        },
        var.argocd_admin_password != "" ? {
          secret = {
            # Hashed password for admin user
            argocdAdminPassword = var.argocd_admin_password
          }
        } : {}
      )
    })
  ]
}

# ── Create Namespace for Envoy Gateway ──────────────────────────────────────────
resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }
}

# Deploy Envoy Gateway (Gateway API controller) via OCI Helm chart
resource "helm_release" "envoy_gateway" {
  depends_on = [
    kubernetes_namespace_v1.envoy_gateway_system
  ]

  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"
  version    = "v1.1.0"
  namespace  = "envoy-gateway-system"
}

# ── Create Namespace for MetalLB ──────────────────────────────────────────────
# The namespace must be explicitly created and labeled as "privileged" to satisfy PodSecurity standards,
# as MetalLB speaker pods run hostNetwork, hostPorts, and require capabilities like NET_ADMIN.
resource "kubernetes_namespace_v1" "metallb_system" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Deploy MetalLB via Helm
resource "helm_release" "metallb" {
  depends_on = [
    kubernetes_namespace_v1.metallb_system
  ]

  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.8"
  namespace  = "metallb-system"
}

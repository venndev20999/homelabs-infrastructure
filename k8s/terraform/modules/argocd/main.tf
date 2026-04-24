resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled = var.ingress_enabled
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "argocd_route" {
  count = var.ingress_enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-route"
      namespace = var.namespace
    }
    spec = {
      parentRefs = [
        {
          name      = "main-gateway"
          namespace = "default"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "argocd-server"
              port = 80
            }
          ]
        }
      ]
    }
  }
}

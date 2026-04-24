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

resource "null_resource" "argocd_route" {
  count = var.ingress_enabled ? 1 : 0

  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      KUBECONFIG=${path.root}/output/kubeconfig kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd-route
  namespace: ${var.namespace}
spec:
  parentRefs:
  - name: main-gateway
    namespace: default
  hostnames:
  - "argocd.vennpham.work"
  - "argocd.vennpham.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: argocd-server
      port: 80
EOF
    EOT
  }
}

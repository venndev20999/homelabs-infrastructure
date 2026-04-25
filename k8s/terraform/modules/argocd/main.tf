resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  # Production Best Practices: Using External Redis and HA components
  values = [
    yamlencode({
      global = {
        logging = {
          level = "info"
        }
        # External Redis configuration
        redis = {
          address  = "192.168.122.203:6379"
          password = "redis123"
        }
      }
      # Enable HA for core components
      controller = {
        replicas = 2
        resources = {
          requests = {
            cpu    = "200m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "1024Mi"
          }
        }
      }
      server = {
        replicas = 2
        extraArgs = ["--insecure"]
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      repoServer = {
        replicas = 2
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "1024Mi"
          }
        }
      }
      # Disable internal Redis components
      redis = {
        enabled = false
      }
      redis-ha = {
        enabled = false
      }
      # Performance tuning
      configs = {
        cm = {
          "timeout.reconciliation" = "180s"
        }
      }
    })
  ]
}

# ── Gateway API Routing ────────────────────────────────────────────────────────
resource "null_resource" "argocd_route" {
  count = var.ingress_enabled ? 1 : 0

  depends_on = [helm_release.argocd]

  triggers = {
    namespace = var.namespace
    hostname  = "argocd.vennpham.work"
  }

  provisioner "local-exec" {
    command = <<EOT
      KUBECONFIG=${path.root}/output/kubeconfig kubectl apply -f - <<EOF
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: argocd-server-grant
  namespace: ${var.namespace}
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: default
  to:
  - group: ""
    kind: Service
    name: argocd-server
---
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

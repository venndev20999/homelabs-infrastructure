resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  # Production Best Practices: High Availability and Resource Management
  values = [
    yamlencode({
      global = {
        logging = {
          level = "info"
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
        extraArgs = ["--insecure"] # Keep insecure for internal routing behind Gateway
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
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = false # Set to true if Prometheus operator is installed
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
      redis-ha = {
        enabled = true # High Availability Redis
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
# Production best practice: Use ReferenceGrant for cross-namespace routing
resource "null_resource" "argocd_route" {
  count = var.ingress_enabled ? 1 : 0

  depends_on = [helm_release.argocd]

  triggers = {
    # Re-apply if any of these change
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

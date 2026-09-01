# ── ClickStack Namespace ───────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "clickstack" {
  metadata {
    name = var.namespace
  }
}

# ── Deploy ClickStack via Helm ─────────────────────────────────────────────────
# ClickStack packages ClickHouse (storage), HyperDX (UI & API), MongoDB, and OpenTelemetry Collector.
resource "helm_release" "clickstack" {
  depends_on = [
    kubernetes_namespace_v1.clickstack
  ]

  name       = "clickstack"
  repository = "https://hyperdxio.github.io/helm-charts"
  chart      = "clickstack"
  version    = "1.1.1"
  namespace  = kubernetes_namespace_v1.clickstack.metadata[0].name

  values = [
    yamlencode({
      global = {
        storageClassName = var.storage_class_name
        keepPVC          = true
      }

      # ── ClickHouse Database Node ─────────────────────────────────────────────
      # Pinned strictly to the designated high-memory worker node (talos-vm-worker-4-stg)
      clickhouse = {
        enabled = true
        nodeSelector = {
          "kubernetes.io/hostname" = var.clickhouse_node
        }
        persistence = {
          enabled  = true
          dataSize = var.clickhouse_pvc_size
          logSize  = "5Gi"
        }
        resources = {
          requests = {
            cpu    = "1"
            memory = "2Gi"
          }
          limits = {
            cpu    = "4"
            memory = "8Gi"
          }
        }
        config = {
          users = {
            appUserPassword  = var.app_user_password
            otelUserPassword = var.otel_user_password
            otelUserName     = "otelcollector"
          }
          clusterCidrs = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }

      # ── HyperDX UI & API ─────────────────────────────────────────────────────
      # Allowed to run on any remaining worker node
      hyperdx = {
        apiKey = var.hyperdx_api_key
      }

      # ── MongoDB (HyperDX metadata & settings store) ──────────────────────────
      # Allowed to run on any remaining worker node
      mongodb = {
        enabled = true
        persistence = {
          enabled  = true
          dataSize = "10Gi"
        }
      }

      # ── OpenTelemetry Ingestion Collector ────────────────────────────────────
      # Receives OTLP traces (4317 gRPC, 4318 HTTP) and writes directly to ClickHouse
      otel = {
        replicas = 1
      }
    })
  ]
}


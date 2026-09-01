# ── ClickStack Namespace ───────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "clickstack" {
  metadata {
    name = var.namespace
  }
}

# ── 1. Deploy ClickStack Operators (ClickHouse Operator & MongoDB Operator) ────
# Per official docs (https://clickhouse.com/docs/clickstack/deployment/helm),
# ClickStack v2.x/v3.x uses a two-phase install. Operators and CRDs are deployed first.
resource "helm_release" "clickstack_operators" {
  depends_on = [
    kubernetes_namespace_v1.clickstack
  ]

  name       = "clickstack-operators"
  repository = "https://clickhouse.github.io/ClickStack-helm-charts"
  chart      = "clickstack-operators"
  version    = "1.1.0"
  namespace  = kubernetes_namespace_v1.clickstack.metadata[0].name
}

# ── 2. Deploy ClickStack (ClickHouseCluster, KeeperCluster, MongoDB, HyperDX, OTel) ──
resource "helm_release" "clickstack" {
  depends_on = [
    helm_release.clickstack_operators
  ]

  name       = "clickstack"
  repository = "https://clickhouse.github.io/ClickStack-helm-charts"
  chart      = "clickstack"
  version    = "3.2.0"
  namespace  = kubernetes_namespace_v1.clickstack.metadata[0].name

  values = [
    yamlencode({
      # ── HyperDX UI & API Engine ──────────────────────────────────────────────
      hyperdx = {
        config = {
          FRONTEND_URL = var.frontend_url
        }
        secrets = {
          HYPERDX_API_KEY         = var.hyperdx_api_key
          CLICKHOUSE_APP_PASSWORD = var.app_user_password
          CLICKHOUSE_PASSWORD     = var.otel_user_password
          MONGODB_PASSWORD        = var.mongodb_password
        }
      }

      # ── ClickHouse Database & Keeper ─────────────────────────────────────────
      # Pinned strictly to the designated high-memory worker node (talos-vm-worker-4-stg)
      clickhouse = {
        enabled = true
        keeper = {
          spec = {
            replicas = 1
            containerTemplate = {
              securityContext = {
                runAsUser  = 101
                runAsGroup = 101
              }
            }
            podTemplate = {
              nodeSelector = {
                "kubernetes.io/hostname" = var.clickhouse_node
              }
              tolerations = [
                {
                  key      = "dedicated"
                  operator = "Equal"
                  value    = "clickhouse"
                  effect   = "NoSchedule"
                }
              ]
              securityContext = {
                runAsUser           = 101
                runAsGroup          = 101
                fsGroup             = 101
                fsGroupChangePolicy = "Always"
              }
              initContainers = [
                {
                  name  = "init-volume-permissions"
                  image = "busybox:latest"
                  securityContext = {
                    runAsUser    = 0
                    runAsNonRoot = false
                  }
                  command = [
                    "sh",
                    "-c",
                    "mkdir -p /var/lib/clickhouse /var/log/clickhouse-keeper && chown -R 101:101 /var/lib/clickhouse /var/log/clickhouse-keeper && chmod -R 775 /var/lib/clickhouse /var/log/clickhouse-keeper"
                  ]
                  volumeMounts = [
                    {
                      name      = "clickhouse-storage-volume"
                      mountPath = "/var/lib/clickhouse"
                      subPath   = "var-lib-clickhouse"
                    },
                    {
                      name      = "clickhouse-storage-volume"
                      mountPath = "/var/log/clickhouse-keeper"
                      subPath   = "var-log-clickhouse"
                    }
                  ]
                }
              ]
            }
            dataVolumeClaimSpec = {
              storageClassName = var.storage_class_name
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "5Gi"
                }
              }
            }
          }
        }
        cluster = {
          spec = {
            replicas = 1
            shards   = 1
            containerTemplate = {
              image = {
                repository = "clickhouse/clickhouse-server"
                tag        = "25.7-alpine"
              }
              securityContext = {
                runAsUser  = 101
                runAsGroup = 101
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
            }
            podTemplate = {
              nodeSelector = {
                "kubernetes.io/hostname" = var.clickhouse_node
              }
              tolerations = [
                {
                  key      = "dedicated"
                  operator = "Equal"
                  value    = "clickhouse"
                  effect   = "NoSchedule"
                }
              ]
              securityContext = {
                runAsUser           = 101
                runAsGroup          = 101
                fsGroup             = 101
                fsGroupChangePolicy = "Always"
              }
              initContainers = [
                {
                  name  = "init-volume-permissions"
                  image = "busybox:latest"
                  securityContext = {
                    runAsUser    = 0
                    runAsNonRoot = false
                  }
                  command = [
                    "sh",
                    "-c",
                    "mkdir -p /var/lib/clickhouse /var/log/clickhouse-server && chown -R 101:101 /var/lib/clickhouse /var/log/clickhouse-server && chmod -R 775 /var/lib/clickhouse /var/log/clickhouse-server"
                  ]
                  volumeMounts = [
                    {
                      name      = "clickhouse-storage-volume"
                      mountPath = "/var/lib/clickhouse"
                      subPath   = "var-lib-clickhouse"
                    },
                    {
                      name      = "clickhouse-storage-volume"
                      mountPath = "/var/log/clickhouse-server"
                      subPath   = "var-log-clickhouse"
                    }
                  ]
                }
              ]
            }
            dataVolumeClaimSpec = {
              storageClassName = var.storage_class_name
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.clickhouse_pvc_size # 50Gi
                }
              }
            }
          }
        }
      }

      # ── MongoDB Community Instance ───────────────────────────────────────────
      mongodb = {
        enabled = true
      }

      # ── OpenTelemetry Collector ──────────────────────────────────────────────
      otel-collector = {
        enabled = true
        mode    = "deployment"
        image = {
          repository = "docker.clickhouse.com/clickhouse/clickstack-otel-collector"
          tag        = "2.35.0"
        }
      }
    })
  ]
}

# ── 3. Deploy OpenTelemetry Cluster Log Agent (DaemonSet) ──────────────────────
# Runs on every Kubernetes node, tails /var/log/pods/*, and streams cluster logs to ClickStack
resource "helm_release" "otel_agent" {
  depends_on = [
    helm_release.clickstack
  ]

  name       = "otel-agent"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.172.0"
  namespace  = kubernetes_namespace_v1.clickstack.metadata[0].name

  values = [
    yamlencode({
      image = {
        repository = "otel/opentelemetry-collector-k8s"
      }

      mode = "daemonset"

      tolerations = [
        {
          operator = "Exists"
        }
      ]

      presets = {
        logsCollection = {
          enabled = true
        }
        kubernetesAttributes = {
          enabled = true
        }
        hostMetrics = {
          enabled = true
        }
      }

      config = {
        exporters = {
          otlphttp = {
            endpoint = "http://clickstack-otel-collector.clickstack.svc.cluster.local:4318"
            headers = {
              Authorization = var.hyperdx_api_key
            }
          }
        }
        service = {
          pipelines = {
            logs = {
              receivers  = ["filelog"]
              processors = ["memory_limiter", "k8sattributes", "batch"]
              exporters  = ["otlphttp"]
            }
            metrics = {
              receivers  = ["hostmetrics"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["otlphttp"]
            }
          }
        }
      }
    })
  ]
}

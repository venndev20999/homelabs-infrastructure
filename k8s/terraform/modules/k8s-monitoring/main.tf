# Create Namespace for Monitoring
# The namespace is labeled as "privileged" to allow Grafana Alloy (daemonset)
# to mount hostPath pods/containers log directories (/var/log/pods, /var/log/containers).
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Deploy Loki (Log Aggregation) via Helm in SingleBinary mode
resource "helm_release" "loki" {
  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.16.0"
  namespace  = "monitoring"

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      singleBinary = {
        replicas = 1
      }
      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        limits_config = {
          retention_period = "72h"
        }
        compactor = {
          retention_enabled    = true
          delete_request_store = "s3"
        }
        schemaConfig = {
          configs = [
            {
              from         = "2024-01-01"
              store        = "tsdb"
              object_store = "s3"
              schema       = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
        storage = {
          type = "s3"
          bucketNames = {
            chunks = "loki"
            ruler  = "loki"
            admin  = "loki"
          }
          s3 = {
            endpoint         = var.minio_endpoint
            accessKeyId      = var.minio_user
            secretAccessKey  = var.minio_password
            s3ForcePathStyle = true
            insecure         = true
          }
        }
      }
      # Disable scalable replicas as we are in SingleBinary mode
      backend = {
        replicas = 0
      }
      write = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      # Disable self-monitoring to save resources
      monitoring = {
        selfMonitoring = {
          enabled = false
          grafanaAgent = {
            install = false
          }
        }
      }
      gateway = {
        enabled = false
      }
      resultsCache = {
        enabled = false
      }
      chunksCache = {
        enabled = false
      }
    })
  ]
}

# Deploy Tempo (Distributed Tracing) via Helm in SingleBinary mode
resource "helm_release" "tempo" {
  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.10.1"
  namespace  = "monitoring"

  values = [
    yamlencode({
      tempo = {
        auth_enabled = false
        storage = {
          trace = {
            backend = "s3"
            s3 = {
              bucket     = "tempo"
              endpoint   = var.minio_endpoint
              access_key = var.minio_user
              secret_key = var.minio_password
              insecure   = true
            }
          }
        }
      }
    })
  ]
}

# Deploy Prometheus (Metrics Collection) via Helm
resource "helm_release" "prometheus" {
  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.21.0"
  namespace  = "monitoring"

  values = [
    yamlencode({
      alertmanager = {
        enabled = false # Disable alertmanager to save resources
      }
      pushgateway = {
        enabled = false
      }
      server = {
        persistentVolume = {
          size = "10Gi"
        }
        retention = "15d"
      }
    })
  ]
}

# Deploy Grafana (Observability Dashboard) via Helm
resource "helm_release" "grafana" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.prometheus
  ]

  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.5.1"
  namespace  = "monitoring"

  values = [
    yamlencode({
      adminPassword = "admin"
      image = {
        tag = "11.6.11"
      }
      plugins = [
        "grafana-metricsdrilldown-app",
        "grafana-lokiexplore-app 1.0.37",
        "grafana-exploretraces-app"
      ]
      "grafana.ini" = {
        plugins = {
          allow_loading_unsigned_plugins = "grafana-metricsdrilldown-app,grafana-lokiexplore-app,grafana-exploretraces-app"
        }
      }
      persistence = {
        enabled = true
        size    = "10Gi"
      }
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Loki"
              type      = "loki"
              access    = "proxy"
              url       = "http://loki.monitoring.svc.cluster.local:3100"
              isDefault = true
              jsonData = {
                derivedFields = [
                  {
                    datasourceUid = "tempo"
                    matcherRegex  = "traceID=(\\w+)"
                    name          = "TraceID"
                    url           = "$${__value.raw}"
                  }
                ]
              }
            },
            {
              name   = "Tempo"
              type   = "tempo"
              access = "proxy"
              url    = "http://tempo.monitoring.svc.cluster.local:3100"
              uid    = "tempo"
            },
            {
              name   = "Prometheus"
              type   = "prometheus"
              access = "proxy"
              url    = "http://prometheus-server.monitoring.svc.cluster.local:80"
              uid    = "prometheus"
            }
          ]
        }
      }
    })
  ]
}

# Deploy Grafana Alloy (Observability Collector) via Helm
resource "helm_release" "alloy" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.loki,
    helm_release.tempo
  ]

  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "0.2.0"
  namespace  = "monitoring"

  values = [
    yamlencode({
      alloy = {
        # Run as root so Alloy has permission to read node log files
        securityContext = {
          runAsUser = 0
        }
        # Mount node /var/log/pods directories
        mounts = {
          varlog = true
        }
        # Expose gRPC/HTTP OTLP ports to receive traces
        extraPorts = [
          {
            name       = "otlp-grpc"
            port       = 4317
            targetPort = 4317
            protocol   = "TCP"
          },
          {
            name       = "otlp-http"
            port       = 4318
            targetPort = 4318
            protocol   = "TCP"
          }
        ]
        # Custom River observability pipeline
        configMap = {
          create  = true
          content = <<-EOT
            // Discover files on the mounted pod logs filesystem
            local.file_match "pod_logs" {
              path_targets = [
                { __path__ = "/var/log/pods/**/*.log" },
              ]
            }

            // Extract Kubernetes metadata from pod log file paths
            discovery.relabel "pod_logs" {
              targets = local.file_match.pod_logs.targets

              rule {
                source_labels = ["__path__"]
                regex         = "^/var/log/pods/([^_]+)_([^_]+)_([^/_]+)/([^/]+)/[0-9]+.log$"
                target_label  = "namespace"
                replacement   = "$1"
              }

              rule {
                source_labels = ["__path__"]
                regex         = "^/var/log/pods/([^_]+)_([^_]+)_([^/_]+)/([^/]+)/[0-9]+.log$"
                target_label  = "pod"
                replacement   = "$2"
              }

              rule {
                source_labels = ["__path__"]
                regex         = "^/var/log/pods/([^_]+)_([^_]+)_([^/_]+)/([^/]+)/[0-9]+.log$"
                target_label  = "container"
                replacement   = "$4"
              }

              rule {
                source_labels = ["namespace", "container"]
                separator     = "/"
                target_label  = "job"
              }
            }

            // Tail log files and forward them to Loki
            loki.source.file "pod_logs" {
              targets    = discovery.relabel.pod_logs.output
              forward_to = [loki.write.local.receiver]
            }

            // Forward logs to the Loki service
            loki.write "local" {
              endpoint {
                url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
              }
            }

            // Receive OTLP traces over gRPC/HTTP
            otelcol.receiver.otlp "default" {
              grpc {
                endpoint = "0.0.0.0:4317"
              }
              http {
                endpoint = "0.0.0.0:4318"
              }
              output {
                traces = [otelcol.processor.batch.default.input]
              }
            }

            // Batch traces before forwarding
            otelcol.processor.batch "default" {
              output {
                traces = [otelcol.exporter.otlp.tempo.input]
              }
            }

            // Forward traces to the Tempo service
            otelcol.exporter.otlp "tempo" {
              client {
                endpoint = "tempo.monitoring.svc.cluster.local:4317"
                tls {
                  insecure = true
                }
              }
            }
          EOT
        }
      }
    })
  ]
}

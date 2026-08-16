# Create Namespace
resource "kubernetes_namespace_v1" "vpn" {
  metadata {
    name = var.namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Service Account for State Persistence
resource "kubernetes_service_account_v1" "tailscale" {
  metadata {
    name      = "tailscale"
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }
}

# Role to read/write tailscale state secrets
resource "kubernetes_role_v1" "tailscale" {
  metadata {
    name      = "tailscale"
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["tailscale-state"]
    verbs          = ["get", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }
}

# Role Binding
resource "kubernetes_role_binding_v1" "tailscale" {
  metadata {
    name      = "tailscale"
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.tailscale.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.tailscale.metadata[0].name
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }
}

# Secret containing the Tailscale Auth Key
resource "kubernetes_secret_v1" "tailscale_auth" {
  metadata {
    name      = "tailscale-auth"
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }

  data = {
    TS_AUTHKEY = var.tailscale_auth_key
  }

  type = "Opaque"
}

# Subnet Router Deployment
resource "kubernetes_deployment_v1" "tailscale" {
  metadata {
    name      = "tailscale-subnet-router"
    namespace = kubernetes_namespace_v1.vpn.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tailscale-subnet-router"
      }
    }

    template {
      metadata {
        labels = {
          app = "tailscale-subnet-router"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.tailscale.metadata[0].name
        host_network         = false
        dns_policy           = "ClusterFirst"

        container {
          name  = "tailscale"
          image = "tailscale/tailscale:v1.68.1"

          env {
            name = "TS_AUTHKEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.tailscale_auth.metadata[0].name
                key  = "TS_AUTHKEY"
              }
            }
          }

          env {
            name  = "TS_ROUTES"
            value = join(",", var.advertise_routes)
          }

          env {
            name  = "TS_KUBE_SECRET"
            value = "tailscale-state"
          }

          env {
            name  = "TS_USERSPACE"
            value = "false"
          }

          security_context {
            privileged = true
            capabilities {
              add = ["NET_ADMIN"]
            }
          }

          volume_mount {
            name       = "tun"
            mount_path = "/dev/net/tun"
          }
        }

        volume {
          name = "tun"
          host_path {
            path = "/dev/net/tun"
            type = "CharDevice"
          }
        }
      }
    }
  }
}

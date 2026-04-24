# ── Cilium LoadBalancer IP Pool ────────────────────────────────────────────────
resource "kubernetes_manifest" "cilium_ip_pool" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "homelab-pool"
    }
    spec = {
      blocks = [
        { cidr = "192.168.122.200/29" } # IPs: 192.168.122.200 - 192.168.122.207
      ]
    }
  }
}

# ── Cilium L2 Announcement Policy ─────────────────────────────────────────────
resource "kubernetes_manifest" "cilium_l2_policy" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"
    metadata = {
      name = "l2-policy"
    }
    spec = {
      loadBalancerIPs = true
      interfaces      = ["^enp.*"] # Matches common KVM/Libvirt interface names
      nodeSelector = {
        matchLabels = {
          "kubernetes.io/os" = "linux"
        }
      }
    }
  }
}

# ── Default Gateway ────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "default_gateway" {
  depends_on = [kubernetes_manifest.cilium_ip_pool]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "main-gateway"
      namespace = "default"
    }
    spec = {
      gatewayClassName = "cilium"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }
}

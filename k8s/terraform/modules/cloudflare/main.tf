terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# ── Cloudflare DNS Records ───────────────────────────────────────────────────
# Point subdomains to the tunnel
resource "cloudflare_record" "wildcard_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  value   = "${var.tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "root_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = "${var.tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# ── Cloudflare Tunnel Configuration (Remote) ─────────────────────────────────
# This maps hostnames to your internal Gateway IP
resource "cloudflare_tunnel_config" "homelab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = var.tunnel_id

  config {
    # Route all subdomains to the shared Envoy Gateway
    ingress_rule {
      hostname = "*.${var.domain}"
      service  = "http://${var.gateway_ip}:80"
    }
    
    # Route root domain if needed
    ingress_rule {
      hostname = var.domain
      service  = "http://${var.gateway_ip}:80"
    }

    # Catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# ── Kubernetes Deployment ────────────────────────────────────────────────────
# Runs the cloudflared agent in your cluster
resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = "kube-system"
    labels = {
      app = "cloudflared"
    }
  }

  spec {
    replicas = 2 # High Availability

    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }

      spec {
        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:latest"
          args  = [
            "tunnel", 
            "--no-autoupdate", 
            "run", 
            "--token", 
            var.tunnel_secret
          ]

          liveness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          
          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

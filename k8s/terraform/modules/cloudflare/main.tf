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
# Managed Dynamic Records
resource "cloudflare_record" "managed_records" {
  for_each = var.dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = each.value.value # Updated from 'value' to 'content' to fix deprecation
  type    = each.value.type
  proxied = each.value.proxied
}

# Default Tunnel CNAMEs (if not provided in dns_records)
resource "cloudflare_record" "tunnel_root" {
  count   = contains(keys(var.dns_records), "@") ? 0 : 1
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "${var.tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "tunnel_wildcard" {
  count   = contains(keys(var.dns_records), "*") ? 0 : 1
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = "${var.tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# ── Cloudflare Zero Trust Tunnel Configuration (Modern) ──────────────────────
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "platform_tunnel" {
  count = var.manage_tunnel_config ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = var.tunnel_id

  config {
    warp_routing {
      enabled = true
    }

    # 1. Dynamic Ingress Rules (VMs, external services)
    dynamic "ingress_rule" {
      for_each = var.ingress_rules
      content {
        hostname = ingress_rule.value.hostname
        service  = ingress_rule.value.service
        path     = ingress_rule.value.path
      }
    }

    # 2. Default K8s Rule (if gateway_ip is provided)
    dynamic "ingress_rule" {
      for_each = var.gateway_ip != "" ? [1] : []
      content {
        hostname = "*.${var.domain}"
        service  = "http://${var.gateway_ip}:80"
      }
    }

    dynamic "ingress_rule" {
      for_each = var.gateway_ip != "" ? [1] : []
      content {
        hostname = var.domain
        service  = "http://${var.gateway_ip}:80"
      }
    }

    # 3. Catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}
